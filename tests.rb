# Basic test requires
require 'minitest/autorun'
require 'minitest/pride'
require 'byebug'
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
      course_code: (0...3).map { (65 + rand(26)).chr }.join + (0...3).map { rand(0..9) }.join,
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

  def sample_assignment
    Assignment.create(
      name: Faker::Company.catch_phrase,
      active_at: Faker::Date.forward,
      due_at: Faker::Date.forward,
      grades_released: [true, false].sample,
      students_can_submit: [true, false].sample,
      percent_of_grade: (1..100.00).to_a.sample,
      maximum_grade: rand(100.00))
  end

  def test_01_associate_terms_and_schools
    s1 = School.create(name: "S1")
    s2 = School.create(name: "S2")
    t1 = Term.create(name: "T1", school_id: 78, starts_on: Faker::Date.forward, ends_on: Faker::Date.forward)
    t2 = Term.create(name: "T2", school_id: 46, starts_on: Faker::Date.forward, ends_on: Faker::Date.forward)
    s1.terms << t1
    s2.terms << t2
    assert s1.reload.terms.include?(t1)
    assert t1.reload.school == s1
  end

  def test_02_associate_courses_and_terms
    s1 = School.create(name: "S1")
    t1 = Term.create(name: "T3", school_id: 34, starts_on: Faker::Date.forward, ends_on: Faker::Date.forward)
    c1 = Course.create(name: "Z1", course_code: "abc321")
    t1.courses << c1
    s1.terms << t1
    assert c1.reload.school == s1
    assert s1.courses.include?(c1)
  end

  def test_03_associate_students_and_courses
    c4 = Course.create(name: "C4")
    student1 = CourseStudent.create(student_id: 1)
    c4.course_students << student1
    assert c4.course_students.include?(student1)
    assert student1.reload.course_id == c4.id
    before = CourseStudent.count
    c4.destroy
    assert_equal before, CourseStudent.count
  end

  def test_04_associate_assignments_and_courses
    c1 = Course.create(name: "C1", course_code: "xyz123")
    a1 = sample_assignment
    c1.assignments << a1
    assert c1.reload.assignments.include?(a1)
    assert a1.reload.course == c1
    before_course = Course.count
    before_assignment = Assignment.count
    c1.destroy
    assert_equal before_course -1, Course.count
    assert_equal before_assignment -1, Assignment.count
  end

  def test_05_associate_lessons_and_preclass_assignments
    l1 = Lesson.create(name: "L1")
    a1 = Assignment.create(name: "A1")
    a1.lessons << l1
    assert a1.lessons.include?(l1)
    assert l1.pre_class_assignment_id == a1.id
  end

  def test_06_schools_have_courses_through_terms
    c1 = Course.create(name: "bcd432")
    t1 = Term.create(name: "T1")
    s1 = School.create(name: "S1")
    t1.courses << c1
    s1.terms << t1
    assert s1.courses.include?(c1)
  end

  def test_07_validate_lessons_have_names
    l = Lesson.new()
    refute l.save
  end

  def test_07_validate_readings_have_order_number_lesson_id_and_url
    r = Reading.new(order_number: " ", lesson_id: " ", url: " ")
    refute r.save
  end

  def test_08_url_should_be_valid
    r = Reading.create(url: "www.sugarbeanfarm.com")
    assert_no_match(/\A(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?\z/ix, r.url, "invalid url" )
  end

  def test_09_course_code_and_name
    c = Course.create(name: " ")
    refute c.save
  end

  def test_10_course_code_unique_within_given_term_id
    assert Course.create(name: "C7", course_code: "dfe765")
    new_course = Course.new(name: "C8", course_code: 33)
    refute new_course.save
  end

  def test_11_valid_course_code
    valid_code = "/\A[a-zA-Z]{3},[0-9]{3}\z"
    c1 = Course.new(name: "C9", course_code: "z1x2c3")
    refute c1.save
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
    r1 = sample_reading
    r2 = sample_reading
    assert_difference 'Reading.count', 1 do
      l.readings << r1
    end
    assert l.readings.include?(r1)
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
  end

  def test_destroy_course_with_lessons
    c = sample_course
    l1 = sample_lesson
    l2 = sample_lesson
    c.lessons << l1
    assert c.lessons.include?(l1)
    c.destroy
    assert c.destroyed?
    assert l1.destroyed?
    refute l2.destroyed?
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
    c1.course_students << cs1
    assert c1.course_students.include?(cs1)
    refute c2.course_students.include?(cs1)
    c1.destroy
    refute c1.destroyed?
    refute cs1.destroyed?
    refute u1.destroyed?
    c2.destroy
    assert c2.destroyed?
  end

  def test_lesson_association_in_class_assignments
    l = sample_lesson
    a = sample_assignment
    refute a.save
    a.lessons << l
    assert a.lessons.include?(l)
  end

  def test_validate_school_name
    s = School.new()
    refute s.save
  end

  def test_validate_term_dates_and_school
    t = Term.new()
    refute t.save
    t.name = "Test"
    refute t.save
    t.starts_on = Faker::Date.forward
    refute t.save
    t.ends_on = Faker::Date.forward
    refute t.save
    s = School.create(name: "Test")
    t.school_id = s.id
    assert t.save
  end

  def test_validate_user_names_and_email
    u = User.new
    refute u.save
    u.first_name = "David"
    refute u.save
    u.last_name = "Test"
    refute u.save
    u.email = "test#{rand(99999999999999)}@test.com"
    assert u.save
  end

  def test_validate_unique_email
    u1 = User.create(first_name: "Test", last_name: "Test", email: "test@test.com")
    u2 = User.create(first_name: "Test2", last_name: "Test2", email: "test@test.com")
    refute u2.save
  end

  def test_validate_valid_email
    u1 = User.new(first_name: "Test", last_name: "Test", email: "test.com")
    u2 = User.new(first_name: "Test2", last_name: "Test2", email: "test#{rand(99999999999999)}@test.com")
    refute u1.save
    assert u2.save
  end

  def test_validate_valid_photo_url
    u1 = User.new(first_name: "Test", last_name: "Test", email: "test#{rand(99999999999999)}.com", photo_url: "notavalidurl.com")
    u2 = User.new(first_name: "Test2", last_name: "Test2", email: "test#{rand(99999999999999)}@test.com", photo_url: "https://validurl.com")
    u3 = User.new(first_name: "Test2", last_name: "Test2", email: "test#{rand(99999999999999)}@test.com", photo_url: "http://validurl.com")
    refute u1.save
    assert u2.save
    assert u3.save
  end

  def test_valdiate_assignment_validations
    a = Assignment.new
    refute a.save
    a.name = "Something#{rand(99999999999999)}"
    refute a.save
    a.percent_of_grade = rand(100)
    refute a.save
    c = sample_course
    c.assignments << a
    assert a.save
  end

  def test_validate_unique_assignment_name_in_course
    a1 = Assignment.new(name: "Something#{rand(99999999999999)}", percent_of_grade: rand(100))
    a2 = Assignment.new(name: "Duplicate", percent_of_grade: rand(100))
    a3 = Assignment.new(name: "Duplicate", percent_of_grade: rand(100))
    a4 = Assignment.new(name: "Duplicate", percent_of_grade: rand(100))
    c1 = sample_course
    c2 = sample_course
    c1.assignments << a1
    c1.assignments << a2
    assert a1.save
    assert a2.save
    c1.assignments << a3
    c2.assignments << a4
    refute a3.save
    assert a4.save
  end
end
