import SwiftUI
import PhotosUI

struct DailyLogPhotosSection: View {
    @Binding var photos: [DailyLogPhoto]
    @State private var pickerItems: [PhotosPickerItem] = []
    
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
            
            ForEach($photos) { $p in
                VStack(alignment: .leading, spacing: 8) {
                    
                    ZStack(alignment: .topTrailing) {
                        if let uiImage = UIImage(data: p.imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.thinMaterial)
                                .frame(height: 180)
                                .overlay {
                                    Label("圖片讀取失敗", systemImage: "exclamationmark.triangle")
                                        .foregroundStyle(.secondary)
                                }
                        }
                        
                        // ✅ 右上角刪除按鈕（最直覺）
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
                    }
                    
                    TextField("輸入照片說明...", text: $p.caption)
                        .textFieldStyle(.roundedBorder)
                }
                // ✅ 仍保留滑動刪除（可選）
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
