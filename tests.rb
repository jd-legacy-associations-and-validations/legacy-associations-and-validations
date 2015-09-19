# Basic test requires
require 'minitest/autorun'
require 'minitest/pride'
require 'byebug'

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

ActiveRecord::Migration.verbose = false
ActiveSupport::TestCase.test_order = :random

begin ApplicationMigration.migrate(:down); rescue; end
ApplicationMigration.migrate(:up)

# Finally!  Let's test the thing.
class ApplicationTest < ActiveSupport::TestCase



  def test_01_associate_terms_and_schools
    s1 = School.create(name: "S1")
    s2 = School.create(name: "S2")
    t1 = Term.create(name: "T1")
    t2 = Term.create(name: "T2")
    s1.terms << t1
    s2.terms << t2
    assert s1.reload.terms.include?(t1)
    assert t1.reload.school == s1
    # database_version = t2.find(t2.school_id)
    # assert equal [t1], database_version.terms
  end

  # def test_term_association
  #   describe School do
  #     it "should have many terms " do
  #       t = School.reflect_on_association(:terms)
  #       t.macro.should == :has_many
  #     end
  #   end
  # end

  def test_02_associate_courses_and_terms
    t1 = Term.create(name: "T3")
    c1 = Course.create(name: "C1", course_code: "abc321")
    t1.courses << c1
    assert c1.reload.term == t1
    assert t1.courses.include?(c1)
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
    a1 = Assignment.create(name: "A1")
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

# def test_06_
# def test_valid_reading_url
#
#
#
#     validates :order_number,  presence: true
#               :lesson_id, presence: true
#               :url, presence: true, format: { start_with?("http:", "https:")
#
#
#               { with: } url
#
#     class User < ActiveRecord::Base
#   validates :name,  presence: true, length: { maximum: 50 }
#   VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
#   validates :email, presence: true, length: { maximum: 255 },
#                     format: { with: VALID_EMAIL_REGEX }
# end
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
    #assert_no_match(/\A(http|https):\/\/\S+/, r.url, "invalid url" )
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
    assert Course.create(name: "C7", course_code: "cde543")
    new_course = Course.new(name: "C8", course_code: 33)
    refute new_course.save
  end

  def test_12_
    valid_code = "/\A[a-zA-Z]{3},[0-9]{3}\z"
    c1 = Course.new(name: "C9", course_code: valid_code)
    refute c1.save
  end
end
