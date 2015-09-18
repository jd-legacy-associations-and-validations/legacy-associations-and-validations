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
begin ApplicationMigration.migrate(:down); rescue; end
ApplicationMigration.migrate(:up)


# Finally!  Let's test the thing.
class ApplicationTest < Minitest::Test

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
    c1 = Course.create(name: "C1")
    t1.courses << c1
    assert c1.reload.term == t1
  end

  def test_03_associate_students_and_courses
    c1 = Course.create(name: "C1")
    student1 = CourseStudent.create(student_id: 1)
    c1.course_students << student1
    assert student1.reload.course == c1
  end

  def test_truth
    assert true
  end

end
