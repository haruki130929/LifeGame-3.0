import SwiftUI

struct FolderPanelShape: Shape {
    let panelCorner: CGFloat
    let bumpX: CGFloat
    let bumpWidth: CGFloat
    let bumpHeight: CGFloat
    let bumpCorner: CGFloat
    let bumpSlant: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let r = min(panelCorner, min(rect.width, rect.height) / 4)
        
        let topY = rect.minY
        let leftX = rect.minX
        let rightX = rect.maxX
        let bottomY = rect.maxY
        
        let bx0 = clamp(bumpX, leftX + r + 1, rightX - r - bumpWidth - 1)
        let bx1 = bx0 + bumpWidth
        
        let bumpTopY = topY - bumpHeight
        
        let br = min(bumpCorner, bumpHeight / 2)
        let s = min(bumpSlant, bumpWidth / 3)
        
        var p = Path()
        
        p.move(to: CGPoint(x: leftX + r, y: topY))
        
        if bx0 > leftX + r {
            p.addLine(to: CGPoint(x: bx0, y: topY))
        }
        
        p.addLine(to: CGPoint(x: bx0 + s, y: bumpTopY + br))
        p.addQuadCurve(
            to: CGPoint(x: bx0 + s + br, y: bumpTopY),
            control: CGPoint(x: bx0 + s, y: bumpTopY)
        )
        
        p.addLine(to: CGPoint(x: bx1 - s - br, y: bumpTopY))
        
        p.addQuadCurve(
            to: CGPoint(x: bx1 - s, y: bumpTopY + br),
            control: CGPoint(x: bx1 - s, y: bumpTopY)
        )
        
        p.addLine(to: CGPoint(x: bx1, y: topY))
        
        p.addLine(to: CGPoint(x: rightX - r, y: topY))
        p.addQuadCurve(
            to: CGPoint(x: rightX, y: topY + r),
            control: CGPoint(x: rightX, y: topY)
        )
        
        p.addLine(to: CGPoint(x: rightX, y: bottomY - r))
        p.addQuadCurve(
            to: CGPoint(x: rightX - r, y: bottomY),
            control: CGPoint(x: rightX, y: bottomY)
        )
        
        p.addLine(to: CGPoint(x: leftX + r, y: bottomY))
        p.addQuadCurve(
            to: CGPoint(x: leftX, y: bottomY - r),
            control: CGPoint(x: leftX, y: bottomY)
        )
        
        p.addLine(to: CGPoint(x: leftX, y: topY + r))
        p.addQuadCurve(
            to: CGPoint(x: leftX + r, y: topY),
            control: CGPoint(x: leftX, y: topY)
        )
        
        p.closeSubpath()
        return p
    }
    
    private func clamp(_ v: CGFloat, _ minV: CGFloat, _ maxV: CGFloat) -> CGFloat {
        min(max(v, minV), maxV)
    }
}

struct FolderTabShape: Shape {
    var cornerRadius: CGFloat = 14
    var slant: CGFloat = 18
    
    func path(in rect: CGRect) -> Path {
        let r = min(cornerRadius, rect.height / 2)
        let s = min(slant, rect.width / 3)
        
        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY
        
        let leftBottom = CGPoint(x: minX, y: maxY)
        let leftSlopeTop = CGPoint(x: minX + s, y: minY)
        let rightSlopeTop = CGPoint(x: maxX - s, y: minY)
        let rightBottom = CGPoint(x: maxX, y: maxY)
        
        var p = Path()
        p.move(to: leftBottom)
        p.addLine(to: CGPoint(x: leftSlopeTop.x, y: leftSlopeTop.y + r))
        p.addQuadCurve(
            to: CGPoint(x: leftSlopeTop.x + r, y: minY),
            control: CGPoint(x: leftSlopeTop.x, y: minY)
        )
        p.addLine(to: CGPoint(x: rightSlopeTop.x - r, y: minY))
        p.addQuadCurve(
            to: CGPoint(x: rightSlopeTop.x, y: minY + r),
            control: CGPoint(x: rightSlopeTop.x, y: minY)
        )
        p.addLine(to: rightBottom)
        p.addLine(to: leftBottom)
        p.closeSubpath()
        return p
    }
}

struct TabOverlapMask: Shape {
    let overlap: CGFloat
    let cutHeight: CGFloat
    let slant: CGFloat
    let shouldCut: Bool
    
    func path(in rect: CGRect) -> Path {
        guard shouldCut, overlap > 0, cutHeight > 0 else {
            return Path(rect)
        }
        
        let w = rect.width
        let h = rect.height
        
        let cutW = min(overlap, w)
        let cutH = min(cutHeight, h)
        let s = min(slant, cutW)
        
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: w - cutW, y: 0))
        p.addLine(to: CGPoint(x: w - cutW + s, y: cutH))
        p.addLine(to: CGPoint(x: w, y: cutH))
        p.addLine(to: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: 0, y: h))
        p.closeSubpath()
        return p
    }
}
