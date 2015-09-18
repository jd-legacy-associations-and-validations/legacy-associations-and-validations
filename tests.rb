# Basic test requires
require 'minitest/autorun'
require 'minitest/pride'
require 'pry'

# Include both the migration and the app itself
require './migration'
require './application'

# Overwrite the development database connection with a test connection.
ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'test.sqlite3'
)

# Gotta run migrations before we can run tests.  Down will fail the first time,
# so we wrap it in a begin/rescue.
ApplicationMigration.migrate(:down) rescue false
ApplicationMigration.migrate(:up)


# Finally!  Let's test the thing.
class ApplicationTest < ActiveSupport::TestCase

  def sample_lesson
    Lesson.create(
      name: "Test Lesson " << rand(1000).to_s,
      description: "Some description",
      outline: "1.2.3",
      lead_in_question: "Meaning of life",
      slide_html: "<br/>")
  end

  def sample_reading
    Reading.create(
      caption: "The Caption",
      url: "https://example.com",
      order_number: rand(100),
      before_lesson: [true,false].sample)
  end

  def sample_course
    Course.create(
      name: "Test Course",
      course_code: "TST101",
      color: ["Black","Red","Blue","Yellow"].sample,
      period: rand(10),
      description: "Beuller?",
      public: [true, false].sample,
      grading_method: "Assignment",
      use_time_cards: [true,false].sample,
      use_reveal_slides: [true,false].sample,
      use_meeting_video: [true,false].sample,
      use_course_feedback: [true,false].sample)
  end

  def sample_instructor
    User.create(
      title: "Instructor",
      first_name: (A..Z).sample,
      middle_name: (A..Z).sample,
      last_name: (A..Z).sample,
      phone: "411",
      office: "A3432",
      office_hours: "8-5pm",
      photo_url: "https://test.com",
      description: "From a cool university",
      admin: false,
      email: "test@test.com",
      instructor: true,
      code: "A")
  end

  def sample_student
    User.create(
      title: "Student",
      first_name: (A..Z).sample,
      middle_name: (A..Z).sample,
      last_name: (A..Z).sample,
      phone: rand(9999999999).to_s,
      photo_url: "https://test.com",
      description: "Small town boy",
      admin: false,
      email: "test@test.com",
      instructor: false,
      code: rand(9999999999).to_s)
  end

  def test_lesson_association_readings
    l = sample_lesson
    r1 = sample_reading
    r2 = sample_reading
    l.readings << r1
    assert l.reload.readings.include?(r1)
    refute l.readings.include?(r2)
    assert r1.lesson == l
    refute r2.lesson == l
  end

  def test_destroy_lesson_with_readings
    r1, r2 = nil
    l = sample_lesson
    assert_difference 'Reading.count', 2 do
      r1 = sample_reading
      r2 = sample_reading
    end
    l.readings << r1
    assert l.reload.readings.include?(r1)
    assert_difference 'Reading.count', -1 do
      l.destroy
    end
  end

  def test_course_association_lessons
    c = sample_course
    l1 = sample_lesson
    l2 = sample_lesson
    r1 = sample_reading
    r2 = sample_reading
    l1.readings << r1
    c.lessons << l1
    assert c.reload.lessons.include?(l1)
    refute c.lessons.include?(l2)
    assert c.readings.include?(r1)
    refute c.readings.include?(r2)
    assert l1.course == c
    refute l2.course == c
  end

  def test_destroy_course_with_lessons
    c = sample_course
    l1 = sample_lesson
    l2 = sample_lesson
    r1 = sample_reading
    r2 = sample_reading
    l1.readings << r1
    c.lessons << l1
    assert r1.lesson.course == c
    c.destroy
    assert c.destroyed?
    assert l1.destroyed?
    refute l2.destroyed?
    assert r1.destroyed?
    refute r2.destroyed?
  end

  def test_instrucors_association_course
    c = sample_course
    i1 = sample_instructor
    i2 = sample_instructor
    c.course_instructors << i1
    assert c.reload.course_instructors.include?(i1)
    refute c.reload.course_instructors.include?(i2)
    assert_equal c, i1.course
    refute_equal c, i2.course
  end

  def test_destroy_course_with_instructors
    l1, l2 = nil
    c = sample_course
    r1 = sample_reading
    r2 = sample_reading
    assert_difference 'Lesson.count', 2 do
      l1 = sample_lesson
      l2 = sample_lesson
    end
    l1.readings << r1
    c.lessons << l1
    assert_difference 'Lesson.count', -1 do
      c.destroy
    end
    assert c.destroyed?
  end

end
