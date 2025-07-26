import 'package:flutter/material.dart';
import '../models/wellbeing_survey_models.dart';
import '../services/wellbeing_survey_service.dart';

class WellbeingSurveyScreen extends StatefulWidget {
  @override
  _WellbeingSurveyScreenState createState() => _WellbeingSurveyScreenState();
}

class _WellbeingSurveyScreenState extends State<WellbeingSurveyScreen> {
  final Map<String, int?> _responses = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize responses map
    for (final question in WellbeingSurveyQuestion.questions) {
      _responses[question.id] = null;
    }
  }

  bool get _allQuestionsAnswered {
    return _responses.values.every((response) => response != null);
  }

  Future<void> _submitSurvey() async {
    if (!_allQuestionsAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please answer all questions before submitting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = WellbeingSurveyService.createResponse(
        cheerfulSpirits: _responses['cheerful_spirits']!,
        calmRelaxed: _responses['calm_relaxed']!,
        activeVigorous: _responses['active_vigorous']!,
        wokeRested: _responses['woke_rested']!,
        interestingLife: _responses['interesting_life']!,
      );

      await WellbeingSurveyService().insertWellbeingSurvey(response);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wellbeing survey submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Close the screen
      Navigator.of(context).pop();
    } catch (e) {
      print('[WellbeingSurveyScreen] Error submitting survey: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting survey. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildQuestionCard(WellbeingSurveyQuestion question, int index) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${index + 1}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              question.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'How have you felt in the past 2 weeks:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 12),
            ...question.options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final optionText = entry.value;
              
              return RadioListTile<int>(
                title: Text(
                  '$optionIndex = $optionText',
                  style: TextStyle(fontSize: 14),
                ),
                value: optionIndex,
                groupValue: _responses[question.id],
                onChanged: (value) {
                  setState(() {
                    _responses[question.id] = value;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mental Wellbeing Survey'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mental Wellbeing Survey',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please answer all questions about how you have felt in the past 2 weeks.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          
          // Questions
          Expanded(
            child: ListView.builder(
              itemCount: WellbeingSurveyQuestion.questions.length,
              itemBuilder: (context, index) {
                final question = WellbeingSurveyQuestion.questions[index];
                return _buildQuestionCard(question, index);
              },
            ),
          ),
          
          // Submit button
          Container(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _allQuestionsAnswered ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Submitting...'),
                        ],
                      )
                    : Text(
                        'Submit Survey',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
