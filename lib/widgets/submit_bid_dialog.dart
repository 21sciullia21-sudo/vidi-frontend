import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vidi/models/job_model.dart';
import 'package:vidi/models/bid_model.dart';
import 'package:vidi/providers/app_provider.dart';

class SubmitBidDialog extends StatefulWidget {
  final JobModel job;

  const SubmitBidDialog({Key? key, required this.job}) : super(key: key);

  @override
  State<SubmitBidDialog> createState() => _SubmitBidDialogState();
}

class _SubmitBidDialogState extends State<SubmitBidDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _proposalController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _deliveryController.dispose();
    _proposalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Submit Your Bid',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Project: ${widget.job.title}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Color(0xFF3B82F6)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Client Budget: \$${widget.job.budgetMin.toInt()} - \$${widget.job.budgetMax.toInt()}',
                          style: TextStyle(color: Color(0xFF3B82F6)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Your Bid Amount (\$) *',
                          hintText: 'Enter amount',
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val?.isEmpty == true) return 'Required';
                          final amount = double.tryParse(val!);
                          if (amount == null) return 'Invalid amount';
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _deliveryController,
                        decoration: InputDecoration(
                          labelText: 'Delivery Time (days) *',
                          hintText: 'Days',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val?.isEmpty == true) return 'Required';
                          final days = int.tryParse(val!);
                          if (days == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _proposalController,
                  decoration: InputDecoration(
                    labelText: 'Your Proposal *',
                    hintText: 'Explain your approach, experience with similar projects, and why you\'re the best fit...',
                  ),
                  maxLines: 5,
                  validator: (val) => val?.isEmpty == true ? 'Required' : null,
                ),
                SizedBox(height: 12),
                Text(
                  'Tip: Mention relevant experience and how you\'ll deliver exceptional results',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitBid,
                        child: _isSubmitting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.black),
                                ),
                              )
                            : Text('Submit Bid'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitBid() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<AppProvider>();
    final currentUser = provider.currentUser!;

    final bid = BidModel(
      id: Uuid().v4(),
      jobId: widget.job.id,
      editorId: currentUser.id,
      amount: double.parse(_amountController.text),
      deliveryDays: int.parse(_deliveryController.text),
      proposal: _proposalController.text,
      submittedAt: DateTime.now(),
    );

    await provider.submitBid(bid);

    Navigator.pop(context);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bid submitted successfully!')),
    );
  }
}
