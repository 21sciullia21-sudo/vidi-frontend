import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vidi/models/job_model.dart';
import 'package:vidi/models/bid_model.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/widgets/submit_bid_dialog.dart';
import 'package:vidi/pages/user_profile_page.dart';
import 'package:vidi/pages/messages_page.dart';
import 'package:vidi/services/bid_service.dart';
import 'package:vidi/services/job_service.dart';

class JobDetailPage extends StatefulWidget {
  final JobModel job;

  const JobDetailPage({Key? key, required this.job}) : super(key: key);

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  String _sortBy = 'price_low';
  String _filterStatus = 'all';
  double? _minPrice;
  double? _maxPrice;
  int? _maxDeliveryDays;

  List<BidModel> _filterAndSortBids(List<BidModel> bids) {
    var filtered = bids.where((bid) {
      if (_filterStatus != 'all' && bid.status != _filterStatus) return false;
      if (_minPrice != null && bid.amount < _minPrice!) return false;
      if (_maxPrice != null && bid.amount > _maxPrice!) return false;
      if (_maxDeliveryDays != null && bid.deliveryDays > _maxDeliveryDays!) return false;
      return true;
    }).toList();

    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'delivery':
        filtered.sort((a, b) => a.deliveryDays.compareTo(b.deliveryDays));
        break;
      case 'date':
        filtered.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final client = provider.getUserById(widget.job.clientId);
    final isClient = provider.currentUser?.id == widget.job.clientId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Project Details'),
        actions: [
          if (isClient)
            Container(
              margin: EdgeInsets.only(right: 16),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF10B981),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Your Job',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerTheme.color!,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (client != null) ...[
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfilePage(userId: client.id),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFF8B5CF6),
                            child: Text(
                              client.name[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.name,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                'Client',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFF3B82F6).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.job.category,
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      if (client != null && client.isNew)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFFFBBF24),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 14, color: Colors.black),
                              SizedBox(width: 4),
                              Text(
                                'New',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.job.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 12),
                  Text(
                    widget.job.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.attach_money, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        '\$${widget.job.budgetMin.toInt()} - \$${widget.job.budgetMax.toInt()}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Due: ${DateFormat('MMM d, y').format(widget.job.deadline)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        '${widget.job.bidCount} ${widget.job.bidCount == 1 ? 'editor has' : 'editors have'} bid',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.job.referenceImages != null && widget.job.referenceImages.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reference Images',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.job.referenceImages.length,
                        separatorBuilder: (_, __) => SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showImageDialog(context, widget.job.referenceImages[index]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.job.referenceImages[index],
                                width: 160,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 160,
                                  height: 120,
                                  color: Colors.grey[800],
                                  child: Icon(Icons.broken_image, color: Colors.grey[600]),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.job.requirements.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requirements',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 12),
                    Text(
                      widget.job.requirements,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isClient) ...[
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bids Received',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFF8B5CF6).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.job.bidCount} ${widget.job.bidCount == 1 ? 'bid' : 'bids'}',
                            style: TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF1F1F1F),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFF3A3A3A)),
                            ),
                            child: DropdownButton<String>(
                              value: _sortBy,
                              isExpanded: true,
                              underline: SizedBox(),
                              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                              dropdownColor: Color(0xFF1F1F1F),
                              style: TextStyle(color: Colors.white, fontSize: 14),
                              onChanged: (value) => setState(() => _sortBy = value!),
                              items: [
                                DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'delivery', child: Text('Fastest Delivery', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'date', child: Text('Most Recent', style: TextStyle(color: Colors.white))),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF1F1F1F),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFF3A3A3A)),
                            ),
                            child: DropdownButton<String>(
                              value: _filterStatus,
                              isExpanded: true,
                              underline: SizedBox(),
                              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                              dropdownColor: Color(0xFF1F1F1F),
                              style: TextStyle(color: Colors.white, fontSize: 14),
                              onChanged: (value) => setState(() => _filterStatus = value!),
                              items: [
                                DropdownMenuItem(value: 'all', child: Text('All Bids', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'pending', child: Text('Pending', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'accepted', child: Text('Accepted', style: TextStyle(color: Colors.white))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    FutureBuilder<List<BidModel>>(
                      future: provider.getBidsForJob(widget.job.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        var bids = snapshot.data ?? [];
                        
                        if (bids.isEmpty) {
                          return Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text(
                                    'No bids yet',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Check back later for proposals',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        bids = _filterAndSortBids(bids);

                        return Column(
                          children: bids.map((bid) {
                            final editor = provider.getUserById(bid.editorId);
                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Color(0xFF2A2A2A)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Color(0xFF8B5CF6),
                                        child: Text(
                                          (editor?.name ?? 'U')[0].toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              editor?.name ?? 'Unknown',
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                            Text(
                                              editor?.skillLevel ?? 'Editor',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '\$${bid.amount.toInt()}',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              color: Color(0xFF8B5CF6),
                                            ),
                                          ),
                                          Text(
                                            '${bid.deliveryDays} days',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Proposal',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    bid.proposal,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => UserProfilePage(userId: bid.editorId),
                                            ),
                                          ),
                                          icon: Icon(Icons.person_outline, size: 18, color: Colors.white),
                                          label: Text('Profile', style: TextStyle(color: Colors.white)),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Color(0xFF3A3A3A)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MessagesPage(otherUserId: bid.editorId),
                                            ),
                                          ),
                                          icon: Icon(Icons.message_outlined, size: 18, color: Colors.white),
                                          label: Text('Message', style: TextStyle(color: Colors.white)),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Color(0xFF3A3A3A)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                      if (bid.status == 'pending') ...[
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _acceptBid(context, bid),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(0xFF10B981),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: Text('Accept', style: TextStyle(color: Colors.white)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (bid.status == 'accepted')
                                    Container(
                                      margin: EdgeInsets.only(top: 12),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF10B981).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Bid Accepted',
                                            style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: EdgeInsets.all(24),
                child: FutureBuilder<BidModel?>(
                  future: BidService().getUserBidForJob(widget.job.id, provider.currentUser?.id ?? ''),
                  builder: (context, snapshot) {
                    final userBid = snapshot.data;

                    if (userBid != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFF8B5CF6).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Color(0xFF8B5CF6)),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'You\'ve already submitted a bid',
                                    style: TextStyle(color: Color(0xFF8B5CF6)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Your Bid',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFF2A2A2A)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Your Offer',
                                          style: TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '\$${userBid.amount.toInt()}',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Color(0xFF8B5CF6),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Delivery Time',
                                          style: TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${userBid.deliveryDays} days',
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Divider(),
                                SizedBox(height: 12),
                                Text(
                                  'Your Proposal',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  userBid.proposal,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                if (userBid.status == 'accepted') ...[
                                  SizedBox(height: 12),
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF10B981).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.celebration, color: Color(0xFF10B981), size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Congratulations! Your bid was accepted',
                                          style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showSubmitBid(context, widget.job),
                        child: Text('Submit Bid'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSubmitBid(BuildContext context, JobModel job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubmitBidDialog(job: job),
    );
  }

  void _acceptBid(BuildContext context, BidModel bid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accept Bid'),
        content: Text('Accept this bid for \$${bid.amount.toInt()}?\n\nThis will assign the project to this freelancer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF10B981)),
            child: Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final bidService = BidService();
      final jobService = JobService();

      await bidService.acceptBid(bid.id);
      await jobService.assignEditor(widget.job.id, bid.editorId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bid accepted successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 300,
                  color: Colors.grey[800],
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey[600]),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
