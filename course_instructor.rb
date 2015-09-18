class CourseInstructor < ActiveRecord::Base
  belongs_to :course
  belongs_to :instructor, -> { where instructor: true }, class_name: 'User'

end
