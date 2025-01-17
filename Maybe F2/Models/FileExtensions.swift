import Foundation

/// 文件类型分类
enum FileCategory: String, Codable, CaseIterable {
    case all = "全部"
    case text = "文本"
    case image = "图像"
    case audio = "音频"
    case video = "视频"
    case office = "办公文档"
    case archive = "压缩文件"
    case other = "其他"
    
    var icon: String {
        switch self {
        case .all: return "doc"
        case .text: return "doc.text"
        case .image: return "photo"
        case .audio: return "music.note"
        case .video: return "film"
        case .office: return "doc.text.fill"
        case .archive: return "doc.zipper"
        case .other: return "questionmark.folder"
        }
    }
}

/// 文件类型管理器
struct FileExtensions {
    /// 文件类型映射表
    static let categoryExtensions: [FileCategory: [(name: String, ext: String)]] = [
        .text: [
            ("纯文本 (.txt)", "txt"),
            ("Markdown (.md)", "md"),
            ("富文本 (.rtf)", "rtf"),
            ("Swift代码 (.swift)", "swift"),
            ("Python代码 (.py)", "py"),
            ("Java代码 (.java)", "java"),
            ("JavaScript代码 (.js)", "js"),
            ("HTML网页 (.html)", "html"),
            ("CSS样式 (.css)", "css"),
            ("JSON数据 (.json)", "json"),
            ("XML数据 (.xml)", "xml"),
            ("YAML配置 (.yaml)", "yaml"),
            ("配置文件 (.conf)", "conf"),
            ("日志文件 (.log)", "log"),
            ("Shell脚本 (.sh)", "sh")
        ],
        .image: [
            ("PNG图像 (.png)", "png"),
            ("JPEG图像 (.jpg)", "jpg"),
            ("JPEG图像 (.jpeg)", "jpeg"),
            ("GIF动图 (.gif)", "gif"),
            ("HEIC图像 (.heic)", "heic"),
            ("WebP图像 (.webp)", "webp"),
            ("SVG矢量图 (.svg)", "svg"),
            ("BMP位图 (.bmp)", "bmp"),
            ("TIFF图像 (.tiff)", "tiff"),
            ("ICO图标 (.ico)", "ico"),
            ("RAW原始图 (.raw)", "raw"),
            ("PSD设计稿 (.psd)", "psd"),
            ("AI设计稿 (.ai)", "ai"),
            ("EPS矢量图 (.eps)", "eps")
        ],
        .audio: [
            ("MP3音频 (.mp3)", "mp3"),
            ("WAV音频 (.wav)", "wav"),
            ("AAC音频 (.aac)", "aac"),
            ("Apple音频 (.m4a)", "m4a"),
            ("FLAC无损 (.flac)", "flac"),
            ("OGG音频 (.ogg)", "ogg"),
            ("MIDI音乐 (.midi)", "midi"),
            ("MIDI音乐 (.mid)", "mid"),
            ("APE无损 (.ape)", "ape"),
            ("WMA音频 (.wma)", "wma"),
            ("AU音频 (.au)", "au"),
            ("AIFF音频 (.aiff)", "aiff"),
            ("AMR语音 (.amr)", "amr")
        ],
        .video: [
            ("MP4视频 (.mp4)", "mp4"),
            ("MOV视频 (.mov)", "mov"),
            ("AVI视频 (.avi)", "avi"),
            ("MKV视频 (.mkv)", "mkv"),
            ("WMV视频 (.wmv)", "wmv"),
            ("FLV视频 (.flv)", "flv"),
            ("WebM视频 (.webm)", "webm"),
            ("MPEG视频 (.mpeg)", "mpeg"),
            ("MPG视频 (.mpg)", "mpg"),
            ("M4V视频 (.m4v)", "m4v"),
            ("TS视频流 (.ts)", "ts"),
            ("3GP手机视频 (.3gp)", "3gp"),
            ("VOB光盘视频 (.vob)", "vob")
        ],
        .office: [
            ("Word文档 (.docx)", "docx"),
            ("Word旧版 (.doc)", "doc"),
            ("Excel表格 (.xlsx)", "xlsx"),
            ("Excel旧版 (.xls)", "xls"),
            ("PPT演示 (.pptx)", "pptx"),
            ("PPT旧版 (.ppt)", "ppt"),
            ("PDF文档 (.pdf)", "pdf"),
            ("Pages文档 (.pages)", "pages"),
            ("Numbers表格 (.numbers)", "numbers"),
            ("Keynote演示 (.key)", "key"),
            ("OpenDocument文档 (.odt)", "odt"),
            ("OpenDocument表格 (.ods)", "ods"),
            ("OpenDocument演示 (.odp)", "odp"),
            ("CSV表格 (.csv)", "csv")
        ],
        .archive: [
            ("ZIP压缩包 (.zip)", "zip"),
            ("RAR压缩包 (.rar)", "rar"),
            ("7Z压缩包 (.7z)", "7z"),
            ("TAR归档 (.tar)", "tar"),
            ("GZ压缩 (.gz)", "gz"),
            ("BZ2压缩 (.bz2)", "bz2"),
            ("XZ压缩 (.xz)", "xz"),
            ("ISO镜像 (.iso)", "iso"),
            ("DMG镜像 (.dmg)", "dmg")
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