# legacy-associations-and-validations
Source: https://github.com/tiyd-rails-2015-08/legacy_associations_and_validations

# TODO
## Normal Mode
- [x] Associate lessons with readings (both directions). When a lesson is destroyed, its readings should be automatically destroyed.
- [x] Associate lessons with courses (both directions). When a course is destroyed, its lessons should be automatically destroyed.
- [x] Associate courses with course_instructors (both directions). If the course has any students associated with it, the course should not be deletable.
- [ ] Associate lessons with their in_class_assignments (both directions).
- [ ] Set up a Course to have many readings through the Course's lessons.
- [ ] Validate that Schools must have name.
- [ ] Validate that Terms must have name, starts_on, ends_on, and school_id.
- [ ] Validate that the User has a first_name, a last_name, and an email.
- [ ] Validate that the User's email is unique.
- [ ] Validate that the User's email has the appropriate form for an e-mail address. Use a regular expression.
- [ ] Validate that the User's photo_url must start with http:// or https://. Use a regular expression.
- [ ] Validate that Assignments have a course_id, name, and percent_of_grade.
- [ ] Validate that the Assignment name is unique within a given course_id.

## Hard Mode
- [ ] Associate CourseStudents with students (who happen to be users)
- [ ] Associate CourseStudents with assignment_grades (both directions)
- [ ] Set up a Course to have many students through the course's course_students.
- [ ] Associate a Course with its ONE primary_instructor. This primary instructor is the one who is referenced by a course_instructor which has its primary flag set to true.

## Nightmare Mode
- [ ] A Course's students should be ordered by last_name, then first_name.
- [ ] Associate Lessons with their child_lessons (and vice-versa). Sort the child_lessons by id.
