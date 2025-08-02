#!/usr/bin/env python3
"""
Convert XLSForm CSV files to QSF (Qualtrics Survey Format) JSON files
QSF is the format used by Qualtrics for importing/exporting surveys
"""

import pandas as pd
import json
from pathlib import Path
import sys
from datetime import datetime
import uuid

class XLSFormToQSFConverter:
    def __init__(self):
        self.question_counter = 1
        self.block_counter = 1
        
    def generate_question_id(self):
        """Generate a unique question ID for Qualtrics"""
        qid = f"QID{self.question_counter}"
        self.question_counter += 1
        return qid
    
    def generate_block_id(self):
        """Generate a unique block ID for Qualtrics"""
        bid = f"BL_{uuid.uuid4().hex[:8]}"
        self.block_counter += 1
        return bid
    
    def map_question_type(self, xlsform_type):
        """Map XLSForm question types to Qualtrics question types"""
        type_mapping = {
            'text': 'TE',  # Text Entry
            'integer': 'TE',  # Text Entry with validation
            'decimal': 'TE',  # Text Entry with validation
            'select_one': 'MC',  # Multiple Choice - Single Answer
            'select_multiple': 'MC',  # Multiple Choice - Multiple Answer
            'note': 'DB',  # Display Text/Block
            'start': 'Meta',  # Metadata
            'end': 'Meta',  # Metadata
            'date': 'TE',  # Text Entry with date validation
            'time': 'TE',  # Text Entry with time validation
            'datetime': 'TE',  # Text Entry with datetime validation
        }
        
        # Handle compound types
        if xlsform_type.startswith('select_one'):
            return 'MC'
        elif xlsform_type.startswith('select_multiple'):
            return 'MC'
        elif xlsform_type in type_mapping:
            return type_mapping[xlsform_type]
        else:
            return 'TE'  # Default to text entry
    
    def map_question_selector(self, xlsform_type):
        """Map XLSForm types to Qualtrics question selectors"""
        if xlsform_type.startswith('select_one'):
            return 'SAVR'  # Single Answer Vertical
        elif xlsform_type.startswith('select_multiple'):
            return 'MAVR'  # Multiple Answer Vertical
        elif xlsform_type == 'integer' or xlsform_type == 'decimal':
            return 'SL'  # Single Line
        elif xlsform_type == 'text':
            return 'SL'  # Single Line
        elif xlsform_type == 'note':
            return 'DB'  # Display Block
        else:
            return 'SL'  # Default to single line
    
    def create_choice_options(self, xlsform_type, choices_df):
        """Create choice options for select questions"""
        choices = {}
        choice_order = []
        
        # Extract the choice list name from the type
        if xlsform_type.startswith('select_one '):
            list_name = xlsform_type.replace('select_one ', '')
        elif xlsform_type.startswith('select_multiple '):
            list_name = xlsform_type.replace('select_multiple ', '')
        else:
            return choices, choice_order
        
        # Filter choices for this question
        question_choices = choices_df[choices_df['list_name'] == list_name]
        
        for idx, choice in question_choices.iterrows():
            choice_id = str(len(choices) + 1)
            choices[choice_id] = {
                "Display": choice['label']
            }
            choice_order.append(choice_id)
        
        return choices, choice_order
    
    def create_validation(self, xlsform_type, constraint=None):
        """Create validation rules for questions"""
        validation = {}
        
        if xlsform_type == 'integer':
            validation = {
                "Settings": {
                    "ForceResponse": "OFF",
                    "Type": "ValidNumber"
                },
                "Type": "ValidNumber"
            }
        elif xlsform_type == 'decimal':
            validation = {
                "Settings": {
                    "ForceResponse": "OFF",
                    "Type": "ValidDecimal"
                },
                "Type": "ValidDecimal"
            }
        elif constraint and isinstance(constraint, str):
            # Handle custom constraints
            if "between" in constraint:
                validation = {
                    "Settings": {
                        "ForceResponse": "OFF",
                        "Type": "ContentType"
                    },
                    "Type": "ContentType"
                }
        
        return validation
    
    def convert_survey_to_qsf(self, survey_csv, choices_csv, settings_csv, survey_name, survey_description=""):
        """Convert XLSForm CSV files to QSF format"""
        
        # Read CSV files
        survey_df = pd.read_csv(survey_csv)
        choices_df = pd.read_csv(choices_csv)
        settings_df = pd.read_csv(settings_csv)
        
        # Get survey metadata
        survey_id = settings_df.iloc[0]['form_id'] if 'form_id' in settings_df.columns else survey_name.replace(' ', '_')
        survey_title = settings_df.iloc[0]['form_title'] if 'form_title' in settings_df.columns else survey_name
        
        # Create the base QSF structure
        qsf_data = {
            "SurveyEntry": {
                "SurveyID": survey_id,
                "SurveyName": survey_title,
                "SurveyDescription": survey_description,
                "SurveyOwnerID": "UR_placeholder",
                "SurveyBrandID": "placeholder",
                "DivisionID": "placeholder",
                "SurveyLanguage": "EN",
                "SurveyActiveResponseSet": "RS_placeholder",
                "SurveyStatus": "Inactive",
                "SurveyStartDate": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "SurveyExpirationDate": "0000-00-00 00:00:00",
                "SurveyCreationDate": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "CreatorID": "UR_placeholder",
                "LastModified": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "LastAccessed": "0000-00-00 00:00:00",
                "LastActivated": "0000-00-00 00:00:00",
                "Deleted": None
            },
            "SurveyElements": []
        }
        
        # Create survey flow
        flow_elements = []
        block_id = self.generate_block_id()
        
        # Create questions
        questions = {}
        question_order = []
        
        for idx, question in survey_df.iterrows():
            # Skip start/end metadata questions
            if question['type'] in ['start', 'end']:
                continue
                
            qid = self.generate_question_id()
            question_order.append(qid)
            
            # Determine question type and selector
            qtype = self.map_question_type(question['type'])
            selector = self.map_question_selector(question['type'])
            
            # Create question structure
            question_data = {
                "QuestionID": qid,
                "QuestionType": qtype,
                "Selector": selector,
                "Configuration": {
                    "QuestionDescriptionOption": "UseText"
                },
                "QuestionDescription": question['label'],
                "DefaultChoices": False,
                "DataExportTag": question['name'],
                "QuestionText": question['label'],
                "QuestionJS": None,
                "Language": []
            }
            
            # Add hint as sub-text if present
            if pd.notna(question.get('hint', '')):
                question_data["QuestionText"] += f"<br><em>{question['hint']}</em>"
            
            # Handle choice questions
            if question['type'].startswith('select_'):
                choices, choice_order = self.create_choice_options(question['type'], choices_df)
                
                question_data["Choices"] = choices
                question_data["ChoiceOrder"] = choice_order
                
                # Set multiple answers for select_multiple
                if question['type'].startswith('select_multiple'):
                    question_data["Selector"] = "MAVR"
            
            # Add validation if needed
            validation = self.create_validation(question['type'], question.get('constraint'))
            if validation:
                question_data["Validation"] = validation
            
            # Handle note/display questions
            if question['type'] == 'note':
                question_data = {
                    "QuestionID": qid,
                    "QuestionType": "DB",
                    "Selector": "TB",
                    "Configuration": {
                        "QuestionDescriptionOption": "UseText"
                    },
                    "QuestionDescription": question['label'],
                    "QuestionText": question['label'],
                    "DefaultChoices": False,
                    "DataExportTag": question['name'],
                    "Language": []
                }
            
            questions[qid] = question_data
        
        # Create survey block
        survey_block = {
            "Type": "Block",
            "Description": "Default Question Block",
            "ID": block_id,
            "BlockElements": [{"Type": "Question", "QuestionID": qid} for qid in question_order],
            "BlockVisibility": "Expanded"
        }
        
        # Add block to survey elements
        qsf_data["SurveyElements"].append(survey_block)
        
        # Add questions to survey elements
        for qid, question_data in questions.items():
            qsf_data["SurveyElements"].append({
                "Type": "Question",
                "Payload": question_data
            })
        
        # Add survey flow
        flow_element = {
            "Type": "Flow",
            "ID": "FL_1",
            "Flow": [
                {
                    "Type": "Block",
                    "ID": block_id,
                    "FlowID": "FL_1"
                }
            ],
            "Properties": {
                "Count": len(question_order)
            },
            "FlowID": "FL_1"
        }
        
        qsf_data["SurveyElements"].append(flow_element)
        
        return qsf_data
    
    def save_qsf(self, qsf_data, output_file):
        """Save QSF data to JSON file"""
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(qsf_data, f, indent=2, ensure_ascii=False)
            print(f"Successfully created {output_file}")
            return True
        except Exception as e:
            print(f"Error creating {output_file}: {e}")
            return False

def main():
    # Get the current directory
    current_dir = Path(__file__).parent
    
    # Create converter instance
    converter = XLSFormToQSFConverter()
    
    # Convert biweekly survey
    print("Converting Biweekly Wellbeing Survey to QSF format...")
    biweekly_qsf = converter.convert_survey_to_qsf(
        current_dir / 'biweekly_survey_data.csv',
        current_dir / 'biweekly_choices_data.csv',
        current_dir / 'biweekly_settings_data.csv',
        'Biweekly Wellbeing Survey',
        'A biweekly survey to track participant wellbeing across multiple domains including mental, physical, social, environmental, and financial wellbeing.'
    )
    
    biweekly_success = converter.save_qsf(
        biweekly_qsf,
        current_dir / 'Biweekly_Wellbeing_Survey.qsf'
    )
    
    # Reset counter for second survey
    converter.question_counter = 1
    converter.block_counter = 1
    
    # Convert initial survey
    print("Converting Initial Survey to QSF format...")
    initial_qsf = converter.convert_survey_to_qsf(
        current_dir / 'initial_survey_data.csv',
        current_dir / 'initial_choices_data.csv',
        current_dir / 'initial_settings_data.csv',
        'Initial Demographics Survey',
        'An initial survey to collect participant demographics and background information for the Wellbeing Mapping Study.'
    )
    
    initial_success = converter.save_qsf(
        initial_qsf,
        current_dir / 'Initial_Demographics_Survey.qsf'
    )
    
    if biweekly_success and initial_success:
        print("\n✅ Both QSF files created successfully!")
        print("Files created:")
        print("- Biweekly_Wellbeing_Survey.qsf")
        print("- Initial_Demographics_Survey.qsf")
        print("\nThese QSF files can now be imported into Qualtrics:")
        print("1. Log into your Qualtrics account")
        print("2. Go to 'Create Project' → 'Survey' → 'From a file'")
        print("3. Upload the .qsf file")
        print("4. Review and customize the imported survey as needed")
    else:
        print("\n❌ Some QSF files failed to create")
        sys.exit(1)

if __name__ == '__main__':
    main()
