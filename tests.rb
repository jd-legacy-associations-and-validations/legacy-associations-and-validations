# Basic test requires
require 'minitest/autorun'
require 'minitest/pride'
require 'pry'
require 'faker'

# Include both the migration and the app itself
require './migration'
require './application'

# Overwrite the development database connection with a test connection.
ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'test.sqlite3'
)
ActiveRecord::Migration.verbose = false
ActiveSupport::TestCase.test_order = :random

# Gotta run migrations before we can run tests.  Down will fail the first time,
# so we wrap it in a begin/rescue.
ApplicationMigration.migrate(:down) rescue false
ApplicationMigration.migrate(:up)


# Finally!  Let's test the thing.
class ApplicationTest < ActiveSupport::TestCase

  def sample_lesson
    Lesson.create(
      name: "Test Lesson " << rand(1000).to_s,
      description: Faker::Company.catch_phrase,
      outline: "1.2.3",
      lead_in_question: Faker::Company.catch_phrase << "?",
      slide_html: "<br/>")
  end

  def sample_reading
    Reading.create(
      caption: Faker::Book.title,
      url: Faker::Internet.url,
      order_number: rand(100),
      before_lesson: [true,false].sample)
  end

  def sample_course
    Course.create(
      name: Faker::Company.catch_phrase,
      course_code: "TST101",
      color: Faker::Commerce.color,
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
      first_name: Faker::Name.first_name,
      middle_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      phone: rand(9999999999),
      office: Faker::Address.postcode,
      office_hours: "8-5pm",
      photo_url: Faker::Avatar.image,
      description: Faker::Lorem.sentence,
      admin: false,
      email: Faker::Internet.safe_email,
      instructor: true,
      code: Faker::Code.ean)
  end

  def sample_student
    User.create(
      title: "Student",
      first_name: Faker::Name.first_name,
      middle_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      phone: rand(9999999999),
      photo_url: Faker::Avatar.image,
      description: Faker::Lorem.sentence,
      admin: false,
      email: Faker::Internet.safe_email,
      instructor: false,
      code: Faker::Code.ean)
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

  def test_instructors_association_course
    c = sample_course
    u1 = sample_instructor
    u2 = sample_instructor
    ci1 = CourseInstructor.create(course_id: nil, instructor_id: u1.id, primary: true)
    c.course_instructors << ci1
    c.reload
    assert c.course_instructors.include?(ci1)
  end

  def test_destroy_course_with_instructors
    c1 = sample_course
    c2 = sample_course
    u1 = sample_instructor
    u2 = sample_instructor
    u3 = sample_instructor
    ci1, ci2, ci3 = nil
    assert_difference 'CourseInstructor.count', 3 do
      ci1 = CourseInstructor.create(course_id: c1.id, instructor_id: u1.id, primary: true)
      ci2 = CourseInstructor.create(course_id: c1.id, instructor_id: u2.id, primary: false)
      ci3 = CourseInstructor.create(course_id: c2.id, instructor_id: u3.id, primary: true)
    end
    c1.course_instructors << ci1
    c1.course_instructors << ci2
    c2.course_instructors << ci3
    assert c1.course_instructors.include?(ci1)
    assert c1.course_instructors.include?(ci2)
    assert c2.course_instructors.include?(ci3)
    c1.destroy
    assert c1.destroyed?
    assert ci1.destroyed?
    refute u1.destroyed?
    assert ci2.destroyed?
    refute u2.destroyed?
    refute ci3.destroyed?
  end

  def test_destroy_course_with_students
    c1 = sample_course
    c2 = sample_course
    u1 = sample_student
    cs1 = nil
    assert_difference 'CourseStudent.count', 1 do
      cs1 = CourseStudent.create(course_id: c1.id, student_id: u1.id)
    end
    assert c1.course_students.include?(cs1)
    refute c2.course_students.include?(cs1)
    c1.destroy
    refute c1.destroyed?
    refute cs1.destroyed?
    refute u1.destroyed?
    c2.destroy
    assert c2.destroyed?
  end

end
