import Foundation

/// 文件转换错误类型
enum ConversionError: LocalizedError {
    case unsupportedFormat
    case invalidInputFile
    case conversionFailed(String)
    case targetFileExists(String)
    case noPermission(String)
    case insufficientSpace
    case targetFolderNotWritable
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "不支持的文件格式"
        case .invalidInputFile:
            return "无法读取源文件"
        case .conversionFailed(let reason):
            return "转换失败：\(reason)"
        case .targetFileExists(let path):
            return "目标文件已存在：\(path)"
        case .noPermission(let path):
            return "没有权限访问：\(path)"
        case .insufficientSpace:
            return "磁盘空间不足"
        case .targetFolderNotWritable:
            return "目标文件夹没有写入权限"
        }
    }
}

/// 图片格式
enum ImageFormat: String, CaseIterable {
    case jpeg = "jpg"
    case png = "png"
    case gif = "gif"
    case webp = "webp"
    case heic = "heic"
    case tiff = "tiff"
    
    /// 获取格式的描述
    var description: String {
        switch self {
        case .jpeg: return "JPEG 图像"
        case .png: return "PNG 图像"
        case .gif: return "GIF 图像"
        case .webp: return "WebP 图像"
        case .heic: return "HEIC 图像"
        case .tiff: return "TIFF 图像"
        }
    }
    
    /// 获取 UTType
    var utType: String {
        switch self {
        case .jpeg: return "public.jpeg"
        case .png: return "public.png"
        case .gif: return "com.compuserve.gif"
        case .webp: return "public.webp"
        case .heic: return "public.heic"
        case .tiff: return "public.tiff"
        }
    }
}

/// 文件转换协议
protocol FileConverter {
    /// 检查是否支持该转换
    func canConvert(from: String, to: String) -> Bool
    
    /// 执行转换
    func convert(input: URL, output: URL) async throws
} 