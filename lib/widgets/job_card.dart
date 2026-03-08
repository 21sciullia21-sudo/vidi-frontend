import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vidi/models/job_model.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobCard({Key? key, required this.job, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      job.category,
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                job.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 8),
              Text(
                job.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[400],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 18, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    '\$${job.budgetMin.toInt()} - \$${job.budgetMax.toInt()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 6),
                  Text(
                    'Due: ${DateFormat('MMM d, y').format(job.deadline)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 6),
                  Text(
                    'Posted ${_getTimeAgo(job.postedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              SizedBox(height: 16),
              Divider(height: 1),
              SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(0xFF8B5CF6),
                    child: Text(
                      'A',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${job.bidCount} ${job.bidCount == 1 ? 'editor has' : 'editors have'} bid',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      minimumSize: Size(0, 0),
                    ),
                    child: Text('Submit Bid'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) return 'in about ${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'}';
    if (diff.inHours > 0) return 'in about ${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'}';
    if (diff.inMinutes > 0) return 'in about ${diff.inMinutes} minutes';
    return 'just now';
  }
}
