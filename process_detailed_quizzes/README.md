# Process detailed quizzes

This script reads in a `detailed quiz export` file from Coursera, and turns it into a CSV file suitable for analysis in R, SPSS or any other data analysis tool. It is licensed under the BSD license. 

The code is a bit messy, but it seems to work most of the time. It has been run on a number of quizzes, and features have been added to account for all the possibilities in the export format. 

As Coursera transitions to a new `CSV export` format, this script will become less useful, but it is archived here for historical purposes. 

## Other options
The University of Michigan has a [parse-quiz script](https://github.com/coursera-research/parse_quiz) which does much the same thing, but in Python, and a bit differently (reading in the question definitions from an XML file).

## File format

### Questions
The detailed quiz export consists of two parts, the questions (which can include JavaScript blobs used for Likert-style questions) and the answers. Here is an example of the questions:

```
Questions
---------------
Q-0	Did you find the course useful even though you didn’t earn a Statement of Accomplishment?
Q-1	Did you intend to complete the class? 
Q-2	 <script> // ========================================================= function eval_matrix(question_id, matrix_options) { // Concat the values from the groups var result = ''; for(var opt in matrix_options) { result = result + $('input:radio[name='+question_id+'_g'+opt+']:checked').val() + '|'; } $('[name="answer['+question_id+'][answer]"]').val(result); } function setup_matrix_question(question_id, matrix_options, matrix_headings) { $('[name="answer['+question_id+'][display]"]') .before( '<table class="matrix_question table"> \ <thead> \ <tr id="'+question_id+'_head"> \ <th></th> \ </tr> \ </thead> \ <tbody id="'+question_id+'_body"> \ </tbody> \ </table>') .hide(); var $qhead = $('#'+question_id+'_head'); for(var opt in matrix_headings) { $qlabel = $('<th />').text(matrix_headings[opt]); $qhead.append($qlabel); } var $qbody = $('#'+question_id+'_body'); for(var opt in matrix_options) { $qrow = $('<tr />'); $qrow.append($('<td />').css('text-align', 'left').text(matrix_options[opt])); for(var i = 1; i <= matrix_headings.length; i++) { $qrow.append( $('<td />') .append($('<input />').attr({type: 'radio', name: question_id + '_g' + opt, value: i})) ); } $qbody.append($qrow); } // Hook on form submit $('#quiz_form').submit(function() { eval_matrix(question_id, matrix_options); return true; }); } // ========================================================= window.addEventListener('load', function() { setup_matrix_question( 'matrix_q1', [ 'Reduce the weekly time commitment needed to take the course', 'Make the course material easier', 'Make the course material more difficult', 'Making the credential more valuable', 'Make course length shorter' ], [ 'Strongly\n Disagree', 'Disagree', 'Neutral', 'Agree', 'Strongly Agree', ] ); }); </script> If you did intend to complete the class, would the following have made you more likely to complete the class? (Please rate how much you agree with each statement) 
Q-3	Please check any technical problems that kept you from completing the course
```

This is how the file looks like as received from Coursera. There are two regular questions (whether the answer is open-ended, or categorical does not make any difference at this stage), one likerty-style question with JavaScript, an a multiple selection question. The only thing that must be changed is the multiple selection question - we need to provide a list of the options, so that the script can pre-allocate space for dummy variables, like this:

```
Q-4	Please check any technical problems that kept you from completing the course multiple=["The videos didn't work", "My Internet was too slow", "My browser was too old"]
```

This will create one column for each option, and the content will be 1 if the user selected that specific option, and 0 if he/she didn't. 

The column titles are automatically generated based on the questions, so it's also a good idea to shorten these, to make the resulting CSV file more tractable. 

In the JavaScript blob, there are three sections -- the questions, the options, and the header, see the final section with these sections here:

```
'matrix_q1', [ 'Reduce the weekly time commitment needed to take the course', 'Make the course 
material easier', 'Make the course material more difficult', 'Making the credential more valuable', 
'Make course length shorter' ], [ 'Strongly\n Disagree', 'Disagree', 'Neutral', 'Agree', 'Strongly 
Agree', ] ); }); </script> If you did intend to complete the class, would the following have made you 
more likely to complete the class? (Please rate how much you agree with each statement) 
```

We can shorten these in the following manner:

```
'matrix_q1', [ 'reduce-weekly', 'make-easier', 'make-difficult', 'make-credential-valuable', 
'make-shorter' ], [ 'Strongly\n Disagree', 'Disagree', 'Neutral', 'Agree', 'Strongly 
Agree', ] ); }); </script> likely-complete  
```

A complete question header could look like this:

```
Questions
---------------
Q-0	course-useful
Q-1	intend-complete
Q-2	 <script> // ========================================================= function eval_matrix(question_id, matrix_options) { // Concat the values from the groups var result = ''; for(var opt in matrix_options) { result = result + $('input:radio[name='+question_id+'_g'+opt+']:checked').val() + '|'; } $('[name="answer['+question_id+'][answer]"]').val(result); } function setup_matrix_question(question_id, matrix_options, matrix_headings) { $('[name="answer['+question_id+'][display]"]') .before( '<table class="matrix_question table"> \ <thead> \ <tr id="'+question_id+'_head"> \ <th></th> \ </tr> \ </thead> \ <tbody id="'+question_id+'_body"> \ </tbody> \ </table>') .hide(); var $qhead = $('#'+question_id+'_head'); for(var opt in matrix_headings) { $qlabel = $('<th />').text(matrix_headings[opt]); $qhead.append($qlabel); } var $qbody = $('#'+question_id+'_body'); for(var opt in matrix_options) { $qrow = $('<tr />'); $qrow.append($('<td />').css('text-align', 'left').text(matrix_options[opt])); for(var i = 1; i <= matrix_headings.length; i++) { $qrow.append( $('<td />') .append($('<input />').attr({type: 'radio', name: question_id + '_g' + opt, value: i})) ); } $qbody.append($qrow); } // Hook on form submit $('#quiz_form').submit(function() { eval_matrix(question_id, matrix_options); return true; }); } // ========================================================= window.addEventListener('load', function() { setup_matrix_question( 'matrix_q1', [ 'reduce-weekly', 'make-easier', 'make-difficult', 'make-credential-valuable', 'make-shorter' ], [ 'Strongly\n Disagree', 'Disagree', 'Neutral', 'Agree', 'Strongly Agree', ] ); }); </script> likely-complete Q-4	tech-prob multiple=["The videos didn't work", "My Internet was too slow", "My browser was too old"]
```

### Answers

Student answers might look like this

```
Student Answers
---------------

[11344]	Random Student
Q-0	[01] Sat  6 Jul 2013  9:53 AM UTC (UTC +0000)	1.00	Yes, I found the course very useful
Q-1	[01] Sat  6 Jul 2013  9:53 AM UTC (UTC +0000)	1.00	Yes, but the timing was wrong for me - I will try again another time
Q-2	[01] Sat  6 Jul 2013  9:53 AM UTC (UTC +0000)	0.00	
Q-2	[01] Sat  6 Jul 2013  9:53 AM UTC (UTC +0000)	0.00	1|3|4|4|1|
Q-3	[01] Sat  6 Jul 2013  9:53 AM UTC (UTC +0000)	0.00	The videos didn't work
Q-3	[01] Sat  6 Jul 2013  9:53 AM UTC (UTC +0000)	0.00	My Internet was too slow
```

Note the empty line before the likert-style question (Q-2), and the multiple responses to Q-3. 

If we process this file (you can try running `ruby process.rb sample-quiz-export.txt`), we generate a csv file, which looks like this:

```csv
studentid,course-useful,intend-complete,reduce-weekly-likely-complete,make-easier-likely-complete,make-difficult-likely-complete,make-credential-valuable-likely-complete,make-shorter-likely-complete,The_videos_didn't_work,My_Internet_was_too_slow,My_browser_was_too_old
11344,"Yes, I found the course very useful","Yes, but the timing was wrong for me - I will try again another time",Strongly Disagree,Neutral,Agree,Agree,Strongly Disagree,1,1,0
```

Loaded into R, it looks like: 

![](http://reganmian.net/files/coursera-quiz-in-R.png)