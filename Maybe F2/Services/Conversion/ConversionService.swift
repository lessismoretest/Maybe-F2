import Foundation

/// 转换服务管理器
class ConversionService {
    /// 单例
    static let shared = ConversionService()
    
    /// 转换器列表
    private let converters: [FileConverter] = [
        ImageConverter()
    ]
    
    private init() {}
    
    /// 检查是否支持转换
    func canConvert(from: String, to: String) -> Bool {
        converters.contains { $0.canConvert(from: from, to: to) }
    }
    
    /// 获取合适的转换器
    private func getConverter(from: String, to: String) -> FileConverter? {
        converters.first { $0.canConvert(from: from, to: to) }
    }
    
    /// 执行转换
    func convert(input: URL, to outputExtension: String) async throws -> URL {
        let inputExtension = input.pathExtension.lowercased()
        
        // 获取转换器
        guard let converter = getConverter(from: inputExtension, to: outputExtension) else {
            throw ConversionError.unsupportedFormat
        }
        
        // 创建输出路径（在原文件所在目录）
        let outputURL = input.deletingLastPathComponent()
            .appendingPathComponent(input.deletingPathExtension().lastPathComponent + "_converted")
            .appendingPathExtension(outputExtension)
        
        // 如果已存在同名文件，添加数字后缀
        var finalURL = outputURL
        var counter = 1
        while FileManager.default.fileExists(atPath: finalURL.path) {
            finalURL = input.deletingLastPathComponent()
                .appendingPathComponent(input.deletingPathExtension().lastPathComponent + "_converted_\(counter)")
                .appendingPathExtension(outputExtension)
            counter += 1
        }
        
        // 执行转换
        try await converter.convert(input: input, output: finalURL)
        
        return finalURL
    }
    
    /// 获取支持的输出格式
    func getSupportedOutputFormats(for inputExtension: String) -> [ImageFormat] {
        ImageFormat.allCases.filter { format in
            canConvert(from: inputExtension, to: format.rawValue)
        }
    }
} 