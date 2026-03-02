class ClassModel {
  final String id;
  final String className;
  final String board;

  ClassModel({required this.id, required this.className, required this.board});

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
    id: json['_id']?.toString() ?? '',
    className: json['class_name'] ?? '',
    board: json['board'] ?? '',
  );
}

class SubjectModel {
  final String id;
  final String classId;
  final String subjectName;
  final String icon;

  SubjectModel({required this.id, required this.classId, required this.subjectName, required this.icon});

  factory SubjectModel.fromJson(Map<String, dynamic> json) => SubjectModel(
    id: json['_id']?.toString() ?? '',
    classId: json['class_id']?.toString() ?? '',
    subjectName: json['subject_name'] ?? '',
    icon: json['icon'] ?? '',
  );
}

// Represents a single named PDF file
class PdfItem {
  final String name;
  final String url;

  const PdfItem({required this.name, required this.url});

  factory PdfItem.fromJson(dynamic json) {
    if (json is Map) {
      return PdfItem(
        name: json['name']?.toString() ?? 'PDF',
        url: json['url']?.toString() ?? '',
      );
    }
    // Legacy: bare string URL
    return PdfItem(name: 'Chapter Notes', url: json.toString());
  }

  Map<String, dynamic> toJson() => {'name': name, 'url': url};
}

class ChapterModel {
  final String id;
  final String subjectId;
  final int chapterNumber;
  final String chapterName;
  final String description;
  final String pdfUrl;          // legacy single URL
  final List<PdfItem> pdfUrls;  // new multi-PDF list
  final int orderIndex;
  final List<TopicModel> topics;
  final List<VideoModel> videos;

  ChapterModel({
    required this.id,
    required this.subjectId,
    required this.chapterNumber,
    required this.chapterName,
    required this.description,
    required this.pdfUrl,
    this.pdfUrls = const [],
    required this.orderIndex,
    this.topics = const [],
    this.videos = const [],
  });

  /// All PDFs to show: prefer pdf_urls array, fall back to single pdf_url
  List<PdfItem> get allPdfs {
    if (pdfUrls.isNotEmpty) return pdfUrls;
    if (pdfUrl.isNotEmpty) {
      return [PdfItem(name: 'Chapter Notes', url: pdfUrl)];
    }
    return [];
  }

  factory ChapterModel.fromJson(Map<String, dynamic> json) => ChapterModel(
    id: json['_id']?.toString() ?? '',
    subjectId: json['subject_id']?.toString() ?? '',
    chapterNumber: json['chapter_number'] ?? 0,
    chapterName: json['chapter_name'] ?? '',
    description: json['description'] ?? '',
    pdfUrl: json['pdf_url'] ?? '',
    pdfUrls: (json['pdf_urls'] as List<dynamic>?)
        ?.map((p) => PdfItem.fromJson(p))
        .toList() ?? [],
    orderIndex: json['order_index'] ?? 0,
    topics: (json['topics'] as List<dynamic>?)
        ?.map((t) => TopicModel.fromJson(t))
        .toList() ?? [],
    videos: (json['videos'] as List<dynamic>?)
        ?.map((v) => VideoModel.fromJson(v))
        .toList() ?? [],
  );
}

class TopicModel {
  final String id;
  final String chapterId;
  final String topicName;
  final String content;
  final int orderIndex;

  TopicModel({
    required this.id,
    required this.chapterId,
    required this.topicName,
    required this.content,
    required this.orderIndex,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) => TopicModel(
    id: json['_id']?.toString() ?? '',
    chapterId: json['chapter_id']?.toString() ?? '',
    topicName: json['topic_name'] ?? '',
    content: json['content'] ?? '',
    orderIndex: json['order_index'] ?? 0,
  );
}

class VideoModel {
  final String id;
  final String chapterId;
  final String youtubeVideoId;
  final String youtubeUrl;
  final String embedUrl;
  final String title;
  final String duration;

  VideoModel({
    required this.id,
    required this.chapterId,
    required this.youtubeVideoId,
    required this.youtubeUrl,
    required this.embedUrl,
    required this.title,
    required this.duration,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) => VideoModel(
    id: json['_id']?.toString() ?? '',
    chapterId: json['chapter_id']?.toString() ?? '',
    youtubeVideoId: json['youtube_video_id'] ?? '',
    youtubeUrl: json['youtube_url'] ?? '',
    embedUrl: json['embed_url'] ?? '',
    title: json['title'] ?? '',
    duration: json['duration'] ?? '',
  );
}

class ProgressModel {
  final String userId;
  final String chapterId;
  final double completionPercentage;
  final String? lastAccessed;

  ProgressModel({
    required this.userId,
    required this.chapterId,
    required this.completionPercentage,
    this.lastAccessed,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) => ProgressModel(
    userId: json['user_id']?.toString() ?? '',
    chapterId: json['chapter_id']?.toString() ?? '',
    completionPercentage: (json['completion_percentage'] ?? 0).toDouble(),
    lastAccessed: json['last_accessed']?.toString(),
  );
}