"""Valida el proyecto sin Xcode. Ejecutar: python scripts/verify_project.py"""
from collections import Counter
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / "CampusVoteJurado.xcodeproj/project.pbxproj"
text = PBX.read_text(encoding="utf-8-sig")
pattern = r'/\*.*?\*/|//[^\n]*|"(?:\\.|[^"\\])*"|[{}();=,]|[^\s{}();=,]+'
tokens = [m[0] for m in re.finditer(pattern, text, re.S)
          if not m[0].startswith(("/*", "//"))]
position = 0


def take(expected=None):
    global position
    value = tokens[position]
    position += 1
    assert expected is None or value == expected, (expected, value, position)
    return value


def parse():
    if tokens[position] == "{":
        take("{")
        result = {}
        while tokens[position] != "}":
            key = parse()
            take("=")
            assert key not in result, f"Clave/ID duplicado: {key}"
            result[key] = parse()
            take(";")
        take("}")
        return result
    if tokens[position] == "(":
        take("(")
        result = []
        while tokens[position] != ")":
            result.append(parse())
            if tokens[position] != ")":
                take(",")
        take(")")
        return result
    value = take()
    return value[1:-1] if value.startswith('"') else value


project = parse()
assert position == len(tokens), "Contenido extra en pbxproj"
assert project["objectVersion"] == "56"
objects = project["objects"]
assert all(re.fullmatch(r"[0-9A-Fa-f]{24}", key) for key in objects)
file_paths = {}
parents = Counter()


def visit(identifier, parent, ancestors=()):
    assert identifier in objects, f"Referencia inexistente: {identifier}"
    assert identifier not in ancestors, f"Ciclo de grupos: {identifier}"
    item = objects[identifier]
    if item["isa"] == "PBXGroup":
        folder = parent / item.get("path", "")
        for child in item["children"]:
            parents[child] += 1
            visit(child, folder, ancestors + (identifier,))
    elif item["isa"] == "PBXFileReference" and item.get("path", "").endswith(".swift"):
        assert item["sourceTree"] == "<group>"
        file_paths[identifier] = (parent / item["path"]).resolve()


visit(objects[project["rootObject"]]["mainGroup"], ROOT)
disk = {p.resolve() for p in ROOT.rglob("*.swift") if ".git" not in p.parts}
references = {identifier for identifier, item in objects.items()
              if item["isa"] == "PBXFileReference" and item.get("path", "").endswith(".swift")}
assert references == set(file_paths), "Hay archivos Swift fuera de los grupos"
assert set(file_paths.values()) == disk, (
    "Disco sin referencia", disk - set(file_paths.values()),
    "Referencia sin archivo", set(file_paths.values()) - disk)
assert all(count == 1 for count in Counter(file_paths.values()).values())
assert all(parents[identifier] == 1 for identifier in file_paths)

sources = Counter()
for item in objects.values():
    if item["isa"] == "PBXSourcesBuildPhase":
        for build_id in item["files"]:
            assert build_id in objects
            build = objects[build_id]
            assert build["isa"] == "PBXBuildFile"
            assert build["fileRef"] in objects
            sources[build["fileRef"]] += 1
assert set(sources) == references, "Sources no coincide con los archivos Swift"
assert all(sources[identifier] == 1 for identifier in references)

maximum = 0


def check_delimiters(source, path):
    """Control lexico de delimitadores, incluyendo interpolacion; no es un compilador."""
    index = 0

    def code(terminator=None):
        nonlocal index
        stack = []
        while index < len(source):
            char = source[index]
            if source.startswith("//", index):
                newline = source.find("\n", index)
                index = len(source) if newline < 0 else newline + 1
                continue
            if source.startswith("/*", index):
                depth = 1
                index += 2
                while index < len(source) and depth:
                    if source.startswith("/*", index):
                        depth += 1
                        index += 2
                    elif source.startswith("*/", index):
                        depth -= 1
                        index += 2
                    else:
                        index += 1
                assert depth == 0, f"Comentario sin cerrar: {path}"
                continue
            if char == '"':
                index += 1
                while index < len(source):
                    if source.startswith('\\(', index):
                        index += 2
                        code(")")
                    elif source[index] == "\\":
                        index += 2
                    elif source[index] == '"':
                        index += 1
                        break
                    else:
                        index += 1
                else:
                    raise AssertionError(f"Cadena sin cerrar: {path}")
                continue
            index += 1
            if terminator == char and not stack:
                return
            if char in "({[":
                stack.append(char)
            elif char in ")}]":
                assert stack and stack.pop() == dict(zip(")}]", "({["))[char], (path, index, char)
        assert not stack and terminator is None, (path, stack, terminator)

    code()


for path in disk:
    content = path.read_text(encoding="utf-8-sig")
    lines = len(content.splitlines())
    maximum = max(maximum, lines)
    assert lines <= 250, f"{path}: {lines} lineas"
    assert "\ufffd" not in content, f"Caracter de reemplazo en {path}"
    check_delimiters(content, path)

catalog = json.loads((ROOT / "CampusVoteJurado/Localizable.xcstrings").read_text(encoding="utf-8-sig"))
for key, item in catalog["strings"].items():
    for language in ("es", "en"):
        unit = item["localizations"][language]["stringUnit"]
        assert unit["value"], (key, language)
        assert unit["state"] == "translated", (key, language)

settings = [item["buildSettings"] for item in objects.values()
            if item["isa"] == "XCBuildConfiguration" and "PRODUCT_BUNDLE_IDENTIFIER" in item["buildSettings"]]
assert len(settings) == 2
for config in settings:
    assert config["PRODUCT_BUNDLE_IDENTIFIER"] == "pe.campusvote.CampusVoteJurado"
    assert config["GENERATE_INFOPLIST_FILE"] == "YES"
    assert "INFOPLIST_KEY_NSCameraUsageDescription" in config
    deployment = config.get("IPHONEOS_DEPLOYMENT_TARGET")
    if deployment is not None:
        assert float(deployment) == 17
assert all(float(item["buildSettings"]["IPHONEOS_DEPLOYMENT_TARGET"]) == 17
           for item in objects.values() if item["isa"] == "XCBuildConfiguration"
           and "IPHONEOS_DEPLOYMENT_TARGET" in item["buildSettings"])

print(f"OK: {len(disk)} Swift registrados una vez en grupo, FileReference, BuildFile y Sources.")
print(f"OK: IDs unicos de 24 hex; rutas existentes; maximo {maximum}/250 lineas.")
print("OK: delimitadores Swift balanceados, incluidas cadenas e interpolaciones (sin compilar).")
print(f"OK: {len(catalog['strings'])} traducciones ES/EN; bundle, iOS 17 y permiso de camara.")
