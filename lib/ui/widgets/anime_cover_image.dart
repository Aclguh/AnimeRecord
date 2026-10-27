import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 专用于番剧封面海报的磁盘缓存管理器
/// 配置最多缓存 200 张封面对象，缓存过期时间为 30 天，支持 LRU 淘汰以避免私有存储无限膨胀
class AnimeCoverCacheManager {
  static const String key = 'anime_cover_cache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

/// 具备持久化磁盘缓存与自适应占位态的番剧封面图片组件
class AnimeCoverImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final BaseCacheManager? cacheManager;

  const AnimeCoverImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.cacheManager,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = url.trim();
    final effectiveRadius = borderRadius ?? BorderRadius.circular(8);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderBg = isDark ? const Color(0xFF1E2025) : const Color(0xFFF4F4F5);
    final placeholderIconColor = isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA);

    if (cleanUrl.isEmpty) {
      return ClipRRect(
        borderRadius: effectiveRadius,
        child: Container(
          width: width,
          height: height,
          color: placeholderBg,
          child: Center(
            child: Icon(
              Icons.movie_outlined,
              size: 24,
              color: placeholderIconColor,
            ),
          ),
        ),
      );
    }

    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final memWidth = width != null ? (width! * dpr).round() : 200;
    final memHeight = height != null ? (height! * dpr).round() : 300;

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: Container(
        width: width,
        height: height,
        color: placeholderBg,
        child: CachedNetworkImage(
          imageUrl: cleanUrl,
          fit: fit,
          cacheManager: cacheManager ?? AnimeCoverCacheManager.instance,
          memCacheWidth: memWidth,
          memCacheHeight: memHeight,
          maxHeightDiskCache: 600,
          maxWidthDiskCache: 450,
          placeholder: (context, url) => const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 24,
              color: placeholderIconColor,
            ),
          ),
        ),
      ),
    );
  }
}
