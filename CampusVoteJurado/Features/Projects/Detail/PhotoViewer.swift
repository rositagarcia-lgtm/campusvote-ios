import SwiftUI

struct PhotoViewer: View {
    let urls: [String]
    let index: Int
    let onClose: () -> Void

    @State private var page: Int
    @State private var scale: CGFloat = 1

    init(urls: [String], index: Int, onClose: @escaping () -> Void) {
        self.urls = urls
        self.index = index
        self.onClose = onClose
        _page = State(initialValue: index)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $page) {
                ForEach(Array(urls.enumerated()), id: \.offset) { offset, url in
                    ZStack {
                        Color.black
                        AsyncImage(url: URL(string: url)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFit()
                            } else if phase.error != nil {
                                Image(systemName: "photo")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white.opacity(0.7))
                            } else {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .scaleEffect(scale)
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in
                                    scale = min(max(value.magnification, 1), 4)
                                }
                                .onEnded { _ in
                                    if scale < 1.05 { scale = 1 }
                                }
                        )
                    }
                    .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.black)
        }
        .overlay(alignment: .top) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.black.opacity(0.45)))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
            .padding(.trailing, 12)
            .zIndex(10)
        }
    }
}
