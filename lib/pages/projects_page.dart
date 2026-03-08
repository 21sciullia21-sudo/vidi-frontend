import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidi/providers/app_provider.dart';
import 'package:vidi/widgets/job_card.dart';
import 'package:vidi/pages/job_detail_page.dart';

class ProjectsPage extends StatelessWidget {
  final String userId;

  const ProjectsPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Projects'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Posted Jobs'),
              Tab(text: 'Active Bids'),
            ],
          ),
        ),
        body: Consumer<AppProvider>(
          builder: (context, provider, _) {
            final postedJobs = provider.jobs.where((j) => j.clientId == userId).toList();
            final userBids = provider.bids.where((b) => b.editorId == userId).toList();
            final jobsWithBids = userBids
                .map((bid) => provider.jobs.firstWhere(
                      (j) => j.id == bid.jobId,
                      orElse: () => provider.jobs.first,
                    ))
                .toList();

            return TabBarView(
              children: [
                // Posted Jobs Tab
                postedJobs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.work_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No jobs posted yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(16),
                        itemCount: postedJobs.length,
                        separatorBuilder: (_, __) => SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final job = postedJobs[index];
                          return JobCard(
                            job: job,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobDetailPage(job: job),
                              ),
                            ),
                          );
                        },
                      ),
                // Active Bids Tab
                jobsWithBids.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gavel, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No active bids',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(16),
                        itemCount: jobsWithBids.length,
                        separatorBuilder: (_, __) => SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final job = jobsWithBids[index];
                          final bid = userBids.firstWhere((b) => b.jobId == job.id);
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              JobCard(
                                job: job,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => JobDetailPage(job: job),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Color(0xFF8B5CF6), size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'Your bid: \$${bid.amount.toInt()}',
                                      style: TextStyle(
                                        color: Color(0xFF8B5CF6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
