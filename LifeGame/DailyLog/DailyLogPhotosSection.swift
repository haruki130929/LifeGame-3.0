import SwiftUI
import PhotosUI

// MARK: - 全螢幕照片預覽
struct PhotoFullscreenPreview: View {
    let photos: [DailyLogPhoto]
    @Binding var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 左右滑動切換照片
            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    ZoomablePhoto(photo: photo)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .always : .never))
            .ignoresSafeArea()
            
            // 關閉按鈕
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                            .padding()
                            .accessibilityLabel("關閉")
                    }
                }
                Spacer()
                
                // 照片說明文字
                let caption = photos[currentIndex].caption
                if !caption.isEmpty {
                    Text(caption)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .multilineTextAlignment(.center)
                        .shadow(radius: 3)
                }
            }
            
            // 照片數量指示（左上角）
            if photos.count > 1 {
                VStack {
                    HStack {
                        Text("\(currentIndex + 1) / \(photos.count)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.4))
                            .clipShape(Capsule())
                            .padding(.top, 56)
                            .padding(.leading, 16)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - 單張可縮放照片
struct ZoomablePhoto: View {
    let photo: DailyLogPhoto
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(scale)
                    .offset(offset)
                // 雙指縮放
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                if scale < 1.0 {
                                    withAnimation(.spring()) {
                                        scale = 1.0
                                        offset = .zero
                                    }
                                }
                                lastScale = scale
                            }
                    )
                // 縮放後可拖曳
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard scale > 1.0 else { return }
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                // 雙擊還原
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }
            }
        }
    }
}

// MARK: - 照片區塊主體
struct DailyLogPhotosSection: View {
    @Binding var photos: [DailyLogPhoto]
    @State private var pickerItems: [PhotosPickerItem] = []
    
    // 放大預覽狀態
    @State private var isPreviewPresented = false
    @State private var previewIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            PhotosPicker(
                selection: $pickerItems,
                maxSelectionCount: 20,
                matching: .images
            ) {
                Label("加入照片", systemImage: "photo.on.rectangle.angled")
            }
            .onChange(of: pickerItems) { _, newItems in
                Task {
                    await appendSelectedPhotos(newItems)
                    pickerItems = []
                }
            }
            
            if photos.isEmpty {
                Text("尚未加入照片")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
            
            ForEach(Array($photos.enumerated()), id: \.element.id) { index, $p in
                VStack(alignment: .leading, spacing: 8) {
                    
                    ZStack(alignment: .topTrailing) {
                        if let uiImage = UIImage(data: p.imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            // ✅ 點擊放大預覽
                                .onTapGesture {
                                    previewIndex = index
                                    isPreviewPresented = true
                                }
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.thinMaterial)
                                .frame(height: 180)
                                .overlay {
                                    Label("圖片讀取失敗", systemImage: "exclamationmark.triangle")
                                        .foregroundStyle(.secondary)
                                }
                        }
                        
                        // 右上角刪除按鈕
                        Button {
                            deletePhoto(id: p.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .shadow(radius: 3)
                                .padding(8)
                        }
                        .buttonStyle(.plain)
                        
                        // ✅ 右下角放大提示圖示
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(.black.opacity(0.35))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .padding(8)
                            }
                        }
                        .frame(height: 180)
                        .allowsHitTesting(false)
                    }
                    
                    TextField("輸入照片說明...", text: $p.caption)
                        .textFieldStyle(.roundedBorder)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        deletePhoto(id: p.id)
                    } label: {
                        Label("刪除", systemImage: "trash")
                    }
                }
                .padding(.vertical, 4)
            }
        }
        // ✅ 全螢幕預覽
        .fullScreenCover(isPresented: $isPreviewPresented) {
            PhotoFullscreenPreview(
                photos: photos,
                currentIndex: $previewIndex
            )
        }
    }
    
    private func deletePhoto(id: UUID) {
        photos.removeAll { $0.id == id }
    }
    
    private func appendSelectedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                photos.append(DailyLogPhoto(imageData: data, caption: ""))
            }
        }
    }
}
