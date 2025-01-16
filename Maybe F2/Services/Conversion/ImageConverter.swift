import Foundation
import AppKit
import UniformTypeIdentifiers
import ImageIO
import WebKit

/// 图片转换器
class ImageConverter: FileConverter {
    /// 支持的图片格式
    private let supportedFormats: [ImageFormat] = [
        .jpeg,
        .png,
        .gif,
        .tiff
    ]
    
    /// 检查是否支持该转换
    func canConvert(from: String, to: String) -> Bool {
        guard let fromFormat = ImageFormat(rawValue: from.lowercased()),
              let toFormat = ImageFormat(rawValue: to.lowercased()) else {
            return false
        }
        // 暂时只支持基本格式之间的转换
        return supportedFormats.contains(fromFormat) && supportedFormats.contains(toFormat)
    }
    
    /// 执行转换
    func convert(input: URL, output: URL) async throws {
        // 读取源图片
        guard let imageSource = CGImageSourceCreateWithURL(input as CFURL, nil) else {
            throw ConversionError.invalidInputFile
        }
        
        // 获取输出格式
        guard let outputFormat = ImageFormat(rawValue: output.pathExtension.lowercased()) else {
            throw ConversionError.unsupportedFormat
        }
        
        // 获取源图像
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ConversionError.conversionFailed("无法读取源图像")
        }
        
        // 创建 NSImage
        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        
        // 根据输出格式选择转换方法
        let imageData: Data?
        let properties: [NSBitmapImageRep.PropertyKey: Any] = [.compressionFactor: 0.9]
        
        if let bitmapRep = NSBitmapImageRep(data: image.tiffRepresentation ?? Data()) {
            switch outputFormat {
            case .jpeg:
                imageData = bitmapRep.representation(using: .jpeg, properties: properties)
            case .png:
                imageData = bitmapRep.representation(using: .png, properties: [:])
            case .gif:
                imageData = bitmapRep.representation(using: .gif, properties: [:])
            case .tiff:
                imageData = bitmapRep.representation(using: .tiff, properties: [:])
            default:
                throw ConversionError.unsupportedFormat
            }
        } else {
            throw ConversionError.conversionFailed("无法创建位图表示")
        }
        
        // 写入文件
        guard let data = imageData else {
            throw ConversionError.conversionFailed("无法生成输出数据")
        }
        
        try data.write(to: output)
    }
} 