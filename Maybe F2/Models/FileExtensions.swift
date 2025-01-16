import Foundation

/// 文件类型分类
enum FileCategory: String, CaseIterable {
    case text = "文本"
    case image = "图像"
    case audio = "音频"
    case video = "视频"
    case office = "办公文档"
    case archive = "压缩文件"
    case other = "其他"
}

/// 文件类型管理器
struct FileExtensions {
    /// 文件类型映射表
    static let categoryExtensions: [FileCategory: [(name: String, ext: String)]] = [
        .text: [
            ("纯文本", "txt"),
            ("Markdown", "md"),
            ("富文本", "rtf"),
            ("代码", "swift"),
            ("HTML", "html")
        ],
        .image: [
            ("PNG图像", "png"),
            ("JPEG图像", "jpg"),
            ("GIF动图", "gif"),
            ("HEIC图像", "heic"),
            ("WebP图像", "webp")
        ],
        .audio: [
            ("MP3音频", "mp3"),
            ("WAV音频", "wav"),
            ("AAC音频", "aac"),
            ("Apple音频", "m4a")
        ],
        .video: [
            ("MP4视频", "mp4"),
            ("MOV视频", "mov"),
            ("AVI视频", "avi"),
            ("MKV视频", "mkv")
        ],
        .office: [
            ("Word文档", "docx"),
            ("Excel表格", "xlsx"),
            ("PPT演示", "pptx"),
            ("PDF文档", "pdf"),
            ("Pages文档", "pages"),
            ("Numbers表格", "numbers"),
            ("Keynote演示", "key")
        ],
        .archive: [
            ("ZIP压缩包", "zip"),
            ("RAR压缩包", "rar"),
            ("7Z压缩包", "7z")
        ],
        .other: [
            ("保持原后缀", "")
        ]
    ]
    
    /// 获取所有支持的后缀名
    static var allExtensions: [String] {
        categoryExtensions.values.flatMap { $0.map { $0.ext } }
    }
    
    /// 根据后缀名获取对应的类别
    static func category(for extension: String) -> FileCategory {
        for (category, extensions) in categoryExtensions {
            if extensions.contains(where: { $0.ext.lowercased() == `extension`.lowercased() }) {
                return category
            }
        }
        return .other
    }
} 