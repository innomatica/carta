import 'dart:io';

enum WebDavResourceType { collection }

class WebDavResource {
  String href;
  DateTime? creationDate;
  String? displayName;
  String? contentLanguage;
  int? contentLength;
  ContentType? contentType;
  String? etag;
  DateTime? lastModified;
  WebDavResourceType? resourceType;

  WebDavResource({
    required this.href,
    this.creationDate,
    this.displayName,
    this.contentLanguage,
    this.contentLength,
    this.contentType,
    this.etag,
    this.lastModified,
    this.resourceType,
  });

  @override
  String toString() {
    return {
      'href': href,
      'creationDate': creationDate?.toLocal(),
      'displayName': displayName,
      'contentLanguage': contentLanguage,
      'contentLength': contentLength,
      'contentType': contentType,
      'etag': etag,
      'lastModified': lastModified?.toLocal(),
      'resourceType': resourceType,
    }.toString();
  }
}

class NextCloudResource extends WebDavResource {
  int? id;
  int? fileId;
  int? favorite;
  String? commentsHref;
  int? commentsCount;
  bool? commentsUnread;
  int? ownerId;
  String? ownerDisplayName;
  String? shareTypes;
  String? checksums;
  bool? hasPreview;
  int? size;
  String? richWorkspace;
  int? containedFolderCount;
  int? containedFileCount;
  String? permissions;

  NextCloudResource({
    required super.href,
    super.contentLength,
    super.contentType,
    super.etag,
    super.lastModified,
    super.resourceType,
    this.id,
    this.fileId,
    this.favorite,
    this.commentsHref,
    this.commentsCount,
    this.commentsUnread,
    this.ownerId,
    this.ownerDisplayName,
    this.shareTypes,
    this.checksums,
    this.hasPreview,
    this.size,
    this.richWorkspace,
    this.containedFolderCount,
    this.containedFileCount,
    this.permissions,
  });

  @override
  String toString() {
    return {
      'href': href,
      'lastModified': lastModified?.toLocal(),
      'etag': etag,
      'resourceType': resourceType,
      'contentType': contentType,
      'contentLength': contentLength,
      'id': id,
      'fileId': fileId,
      'favorite': favorite,
      'commentsHref': commentsHref,
      'commentsCount': commentsCount,
      'commentsUnread': commentsUnread,
      'ownerId': ownerId,
      'owerDisplayName': ownerDisplayName,
      'shareTypes': shareTypes,
      'checksums': checksums,
      'hasPreview': hasPreview,
      'size': size,
      'richWorkspace': richWorkspace,
      'containedFileCount': containedFileCount,
      'containedFolderCount': containedFolderCount,
      'permissions': permissions,
    }.toString();
  }
}
