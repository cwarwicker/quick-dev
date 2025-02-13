<?php
define('CLI_SCRIPT', true);

require_once 'vendor/autoload.php';
require_once 'config.php';
require_once($CFG->libdir . '/clilib.php');
require_once($CFG->dirroot . '/lib/phpunit/classes/util.php');

[$options, $unrecognized] = cli_get_params(
    [
        'help' => false,
        'course' => false,
        'questions' => false,
    ]
);

if ($unrecognized) {
    $unrecognized = implode("\n  ", $unrecognized);
    cli_error(get_string('cliunknowoption', 'admin', $unrecognized));
}

if ($options['help']) {
    $help =
        "Create a quiz on a course with <x> amount of questions.

This only works on Moodle versions with mod_qbank installed.

Options:
--help               Print out this help
--course             The course shortname to add questions to
--questions          The number of questions to add

";

    echo $help;
    die;
}

if ($options['course'] === false) {
    cli_error('Course shortname must be specified');
}

if ($options['questions'] === false || !ctype_digit($options['questions']) || $options['questions'] < 1) {
    cli_error('Valid question count must be specified');
}

$course = $DB->get_record('course', ['shortname' => $options['course']], '*', MUST_EXIST);

$generator = phpunit_util::get_data_generator();
$quizgenerator = $generator->get_plugin_generator('mod_quiz');
$questiongenerator = $generator->get_plugin_generator('core_question');
$bankgenerator = $generator->get_plugin_generator('mod_qbank');

// Create a question bank activity.
$questionbank = $bankgenerator->create_instance(['course' => $course->id]);
$context = \core\context\module::instance(
    get_coursemodule_from_instance('qbank', $questionbank->id, $course->id)->id
);

// Create a category within the question bank.
$cat = $questiongenerator->create_question_category(['contextid' => $context->id]);

// Then create the questions for the course and add them to the category.
// Use these types for the questions we are creating.
$types = ['truefalse', 'shortanswer', 'essay'];
$counttypes = count($types);

$questions = [];
for ($j = 0; $j < $options['questions']; $j++) {
    $type = $types[mt_rand(0, $counttypes - 1)];
    $questions[] = $questiongenerator->create_question($type, null, ['category' => $cat->id]);
}

// Now create the quiz activity and add questions to it.
$quiz = $quizgenerator->create_instance(['course' => $course->id]);

// Add all the questions to the quiz.
for ($i = 0; $i < $options['questions']; $i++) {
    quiz_add_quiz_question($questions[$i]->id, $quiz);
}

cli_writeln('Quiz questions generated: ' . $CFG->wwwroot . '/mod/quiz/edit.php?cmid=' . $quiz->cmid);
