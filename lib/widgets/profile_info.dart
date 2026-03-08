import 'package:flutter/material.dart';
import 'package:vidi/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vidi/widgets/post_card.dart';

class ProfileInfo extends StatefulWidget {
  final UserModel user;

  const ProfileInfo({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileInfo> createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo> {
  bool _isResumeExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.user.featuredReelUrl != null && widget.user.featuredReelUrl!.isNotEmpty)
          Container(
            constraints: BoxConstraints(maxWidth: 800),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerTheme.color!.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Color(0xFFFBBF24), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Featured Reel',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: VideoPlayerWidget(videoUrl: widget.user.featuredReelUrl!),
                ),
              ],
            ),
          ),
        if (widget.user.editingStyle != null && widget.user.editingStyle!.isNotEmpty)
          Container(
            constraints: BoxConstraints(maxWidth: 800),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerTheme.color!.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editing Style',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.movie_filter, color: Color(0xFF8B5CF6), size: 20),
                      SizedBox(width: 10),
                      Text(
                        widget.user.editingStyle!,
                        style: TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (widget.user.gearBadges.isNotEmpty)
          Container(
            constraints: BoxConstraints(maxWidth: 800),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerTheme.color!.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gear & Tools',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.user.gearBadges.map((gear) {
                    IconData icon;
                    Color badgeColor;
                    if (gear.toLowerCase().contains('camera') || 
                        gear.toLowerCase().contains('sony') || 
                        gear.toLowerCase().contains('red') ||
                        gear.toLowerCase().contains('canon')) {
                      icon = Icons.videocam;
                      badgeColor = Color(0xFFEF4444);
                    } else if (gear.toLowerCase().contains('resolve') || 
                               gear.toLowerCase().contains('premiere') ||
                               gear.toLowerCase().contains('final cut')) {
                      icon = Icons.video_settings;
                      badgeColor = Color(0xFF3B82F6);
                    } else {
                      icon = Icons.settings;
                      badgeColor = Color(0xFF10B981);
                    }
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 18, color: badgeColor),
                          SizedBox(width: 8),
                          Text(
                            gear,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        Container(
          constraints: BoxConstraints(maxWidth: 800),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerTheme.color!.withValues(alpha: 0.5),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isResumeExpanded = !_isResumeExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Resume',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Icon(
                          _isResumeExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.white,
                          size: 28,
                        ),
                      ],
                    ),
                    if (_isResumeExpanded) ...[
                      SizedBox(height: 20),
                      _InfoRow(
                        label: 'Bio',
                        value: widget.user.bio.isEmpty ? 'No bio added yet' : widget.user.bio,
                      ),
                      SizedBox(height: 16),
                      _InfoRow(
                        label: 'Skill Level',
                        value: widget.user.skillLevel,
                      ),
                      SizedBox(height: 16),
                      _InfoRow(
                        label: 'Hourly Rate',
                        value: widget.user.hourlyRate > 0 ? '\$${widget.user.hourlyRate}/hr' : 'Not set',
                      ),
                      SizedBox(height: 16),
                      _InfoRow(
                        label: 'Location',
                        value: widget.user.location.isEmpty ? 'Not specified' : widget.user.location,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.user.socialLinks.isNotEmpty)
          Container(
            constraints: BoxConstraints(maxWidth: 800),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerTheme.color!.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Social Links',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.user.socialLinks.entries.map((entry) {
                    IconData icon;
                    Color iconColor;
                    switch (entry.key) {
                      case 'instagram':
                        icon = Icons.camera_alt;
                        iconColor = Color(0xFFE1306C);
                        break;
                      case 'twitter':
                        icon = Icons.message;
                        iconColor = Color(0xFF1DA1F2);
                        break;
                      case 'youtube':
                        icon = Icons.play_circle;
                        iconColor = Color(0xFFFF0000);
                        break;
                      case 'linkedin':
                        icon = Icons.work;
                        iconColor = Color(0xFF0A66C2);
                        break;
                      case 'website':
                        icon = Icons.language;
                        iconColor = Color(0xFF8B5CF6);
                        break;
                      default:
                        icon = Icons.link;
                        iconColor = Color(0xFF8B5CF6);
                    }
                    return InkWell(
                      onTap: () => _launchURL(entry.value),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: iconColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 18, color: iconColor),
                            SizedBox(width: 8),
                            Text(
                              entry.key.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        if (widget.user.portfolioLink.isNotEmpty || widget.user.portfolioFile.isNotEmpty)
          Container(
            constraints: BoxConstraints(maxWidth: 800),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerTheme.color!.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 16),
                if (widget.user.portfolioLink.isNotEmpty)
                  InkWell(
                    onTap: () => _launchURL(widget.user.portfolioLink),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link, color: Color(0xFF8B5CF6), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.user.portfolioLink,
                              style: TextStyle(
                                color: Color(0xFF8B5CF6),
                                decoration: TextDecoration.underline,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (widget.user.portfolioFile.isNotEmpty) ...[
                  if (widget.user.portfolioLink.isNotEmpty) SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.file_present, color: Color(0xFF8B5CF6), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.user.portfolioFile,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (widget.user.specializations.isNotEmpty)
          Container(
            constraints: BoxConstraints(maxWidth: 800),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerTheme.color!.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Specializations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.user.specializations
                      .map((spec) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              spec,
                              style: TextStyle(
                                color: Color(0xFF8B5CF6),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      // Use same tab on web to avoid opening a new tab while keeping default behavior on mobile
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_self',
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
