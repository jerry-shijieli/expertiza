describe AssignmentsController do
  include AssignmentHelper

  let(:assignment) do
    build(:assignment, id: 1, name: 'test assignment', instructor_id: 6, staggered_deadline: true,
                       participants: [build(:participant)], teams: [build(:assignment_team)], course_id: 1)
  end
  let(:assignment_form) { double('AssignmentForm') }
  let(:admin) { build(:admin) }
  let(:instructor) { build(:instructor, id: 6) }
  let(:instructor2) { build(:instructor, id: 66) }
  let(:ta) { build(:teaching_assistant, id: 8) }
  let(:student) { build(:student) }
  before(:each) do
    allow(Assignment).to receive(:find).with('1').and_return(assignment)
    stub_current_user(instructor, instructor.role.name, instructor.role)
  end

  describe '#action_allowed?' do
    context 'when params action is edit or update' do
      context 'when the role name of current user is super admin or admin' do
        it 'allows certain action' do
          params = {:id => 1, :action => "edit"}
          allow(ApplicationController).to receive(:current_role_name).and_return("Administrator")
          expect(controller.send(:action_allowed?)).to be true
        end
      end

      context 'when current user is the instructor of current assignment' do
        it 'allows certain action' do
          params = {:id => 1, :action => "update"}
          allow(Assignment).to receive(:find).and_return(assignment)
          allow(ApplicationController).to receive(:current_user).and_return(:instructor)
          # allow(User).to receive(:id).and_return(6)
          expect(controller.send(:action_allowed?)).to be true
        end
      end

      context 'when current user is the ta of the course which current assignment belongs to' do
        it 'allows certain action' do
          # params = {:id => 1, :action => "update"}
          # allow(ApplicationController).to receive(:current_user).and_return(:ta)
          # allow(:ta).to receive(:id).and_return(8)
          # expect(controller.send(:action_allowed?)).to be true
        end
      end

      context 'when current user is a ta but not the ta of the course which current assignment belongs to' do
        it 'does not allow certain action' do
          # params = {:id => 1, :action => "update"}
          # ta2 = build(:teaching_assistant, id: 4)
          # allow(ApplicationController).to receive(:current_user).and_return(ta2)
          # allow(ta2).to receive(:id).and_return(4)
          # allow(TaMapping).to receive(:exist?).with(:ta_id, :course_id).and_return(false)
          # expect(controller.send(:action_allowed?)).to be false
        end
      end

      context 'when current user is the instructor of the course which current assignment belongs to' do
        it 'allows certain action'
      end

      context 'when current user is an instructor but not the instructor of current course or current assignment' do
        it 'does not allow certain action'
      end
    end

    context 'when params action is not edit and update' do
      context 'when the role current user is super admin/admin/instractor/ta' do
        it 'allows certain action except edit and update'
      end

      context 'when the role current user is student' do
        it 'does not allow certain action'
      end
    end
  end

  describe '#toggle_access' do
    it 'changes access permissions of one assignment from public to private or vice versa and redirects to tree_display#list page' do
      params = {:id => 1}
      allow(Assignment).to receive(:find).and_return(assignment)
      allow(assignment).to receive(:private).and_return(!:private)
      allow(assignment).to receive(:save).and_return(true)
      #expect(controller.send(:toggle_access)).to be true
      #expect(response).to redirect_to(list_tree_display_index_path)
    end
  end

  describe '#new' do
    it 'creates a new AssignmentForm object and renders assignment#new page' do

      allow(Assignment).to receive(:new).and_return(:assignment_form)
      expect(:assignment_form).to be ||= current_user
      # allow(AssignmentForm).to receive(:new).and_return(:assignment_form)
      #get :new
      #expect(assigns(:assignment_form)).to be_kind_of(AssignmentForm)
      #expect(response).to render_template(:new)
    end
  end

  describe '#create' do
    # params = {
    #   assignment_form: {
    #     assignment: {
    #       instructor_id: 2,
    #       course_id: 1,
    #       max_team_size: 1,
    #       id: 1,
    #       name: 'test assignment',
    #       directory_path: '/test',
    #       spec_location: '',
    #       show_teammate_reviews: false,
    #       require_quiz: false,
    #       num_quiz_questions: 0,
    #       staggered_deadline: false,
    #       microtask: false,
    #       reviews_visible_to_all: false,
    #       is_calibrated: false,
    #       availability_flag: true,
    #       reputation_algorithm: 'Lauw',
    #       simicheck: -1,
    #       simicheck_threshold: 100
    #     }
    #   }
    # }
    context 'when assignment_form is saved successfully' do
      it 'redirets to assignment#edit page' do
        # af = double('AssignmentForm', :save => true)
        # allow(AssignmentForm).to receive(:new).and_return(af)
        # # allow(AssignmentForm).to receive(:save).and_return(true)
        # post :create, params
        # expect(response).to redirect_to edit_assignment_path
      end
    end

    context 'when assignment_form is not saved successfully' do
      it 'renders assignment#new page' do
        # allow(assignment_form).to receive(:new).and_return(double('AssignmentForm'))
        # allow(assignment_form).to receive(:save).and_return(false)
        # post :create, params
        # expect(response).to redirect_to new_assignment_path
      end
    end
  end

  describe '#edit' do
    context 'when assignment has staggered deadlines' do
      it 'shows an error flash message and renders edit page' do
        allow(SignUpTopic).to receive(:where).with(assignment_id: '1').and_return([
            double('SignUpTopic'), double('SignUpTopic')])
        allow(AssignmentQuestionnaire).to receive(:where).with(assignment_id: '1')
                                              .and_return([double('AssignmentQuestionnaire', questionnaire_id: 666, used_in_round: 1)])
        assignment_due_date = build(:assignment_due_date)
        allow(AssignmentDueDate).to receive(:where).with(parent_id: '1').and_return([assignment_due_date])
        allow(assignment).to receive(:num_review_rounds).and_return(1)
        allow(Questionnaire).to receive(:where).with(id: 666).and_return([double('Questionnaire', type: 'ReviewQuestionnaire')])
        params = {id: 1}
        get :edit, params
        expect(flash.now[:error]).to eq("You did not specify all the necessary rubrics. You need <b>[AuthorFeedback, TeammateReview] </b> of assignment <b>test assignment</b> before saving the assignment. You can assign rubrics <a id='go_to_tabs2' style='color: blue;'>here</a>.")
        expect(response).to render_template(:edit)
      end
    end
  end

  describe '#update' do
    context 'when params does not have key :assignment_form' do
      context 'when assignment is saved successfully' do
        it 'shows a note flash message and redirects to tree_display#index page' do
          allow(Assignment).to receive(:find).with(id: '1').and_return(:assignment)
          allow(assignment).to receive(:save).and_return(true)
          params = {id: 1, course_id: 1}
          post :update, params
          expect(flash.now[:note]).to eq("The assignment was successfully saved.")
          expect(response).to redirect_to list_tree_display_index_path
        end
      end

      context 'when assignment is not saved successfully' do
        it 'shoes an error flash message and redirects to assignments#edit page' do
          allow(Assignment).to receive(:find).with(id: '1').and_return(:assignment)
          allow(assignment).to receive(:save).and_return(false)
          allow(assignment).to receive_message_chain(:errors, :full_messages) {['Assignment not find.', 'Course not find.']}
          params = {id: 1, course_id: 1}
          post :update, params
          expect(flash.now[:error]).to eq("Failed to save the assignment: Assignment not find. Course not find.")
          expect(response).to redirect_to edit_assignment_path assignment.id
        end
      end
    end

    context 'when params has key :assignment_form' do
      params = {
        id: 1,
        course_id: 1,
        assignment_form: {
          assignment_questionnaire: [{"assignment_id" => "1", "questionnaire_id" => "666", "dropdown" => "true",
                                      "questionnaire_weight" => "100", "notification_limit" => "15", "used_in_round" => "1"}],
          assignment: {
            instructor_id: 2,
            course_id: 1,
            max_team_size: 1,
            id: 2,
            name: 'test assignment',
            directory_path: '/test',
            spec_location: '',
            show_teammate_reviews: false,
            require_quiz: false,
            num_quiz_questions: 0,
            staggered_deadline: false,
            microtask: false,
            reviews_visible_to_all: false,
            is_calibrated: false,
            availability_flag: true,
            reputation_algorithm: 'Lauw',
            simicheck: -1,
            simicheck_threshold: 100
          }
        }
      }
      context 'when the timezone preference of current user is nil and assignment form updates attributes successfully' do
        it 'shows an error message and redirects to assignments#edit page' do
          # asg = double('Assignment', instructor_id: 6)
          # asg_form = double('AssignmentForm', id: 0, assignment: asg)
          # allow(asg_form).to receive(:update_attributes).and_return(true)
          # allow(AssignmentForm).to receive(:create_form_object).and_return(asg_form)
          #
          # usr = double('User', timezonepref: nil, parent_id: 1)
          # parent = double('User', timezonepref: "UTC")
          # allow(User).to receive(:find).and_return(parent)
          # allow(ApplicationController).to receive(:current_user).and_return(usr)
          # allow(assignment_form).to receive_message_chain(assignment, instructor).with(usr)
          # post :update, params
          # expect(flash[:error]).to eq("We strongly suggest that instructors specify their preferred timezone to guarantee the correct display time. For now we assume you are in UTC")
          # expect(response).to redirect_to edit_assignment_path asg_form.assignment.id
        end
      end

      context 'when the timezone preference of current user is not nil and assignment form updates attributes not successfully' do
        it 'shows an error message and redirects to assignments#edit page'
      end
    end
  end

  describe '#show' do
    it 'renders assignments#show page' do
      allow(Assignment).to receive(:find).and_return(:assignment)
      get :show
      expect(response).to render_template(:show)
    end
  end

  describe '#copy' do
    context 'when new assignment id fetches successfully' do
      it 'redirects to assignments#edit page' do
        allow(ApplicationController).to receive(:current_user).and_return(:student)
        asg = double('Assignment', id: 1, directory_path: 1)
        allow(Assignment).to receive(:find).and_return(asg)
        allow(AssignmentForm).to receive(:copy).and_return(asg.id)
        params = {id: 1}
        get :copy, params
        expect(response).to redirect_to edit_assignment_path assignment.id
      end
    end

    context 'when new assignment id does not fetch successfully' do
      it 'shows an error flash message and redirects to assignments#edit page' do
        allow(ApplicationController).to receive(:current_user).and_return(:student)
        allow(Assignment).to receive(:find).and_return(:assignment)
        allow(AssignmentForm).to receive(:copy).and_return(nil)
        params = {id: 1}
        get :copy, params
        expect(flash[:error]).to eq('The assignment was not able to be copied. Please check the original assignment for missing information.')
        expect(response).to redirect_to list_tree_display_index_path
      end
    end
  end

  describe '#delete' do
    context 'when assignment is deleted successfully' do
      it 'shows a success flash message and redirects to tree_display#list page' do
        asg = double('Assignment', instructor_id: 6)
        asg_form = double('AssignmentForm', id: 0, assignment: asg)
        allow(asg_form).to receive(:delete)
        allow(AssignmentForm).to receive(:create_form_object).and_return(asg_form)
        session[:user] = double('User', get_instructor: 6)
        params = {id: 0, force: true}
        get :delete, params
        expect(flash[:success]).to eq("The assignment was successfully deleted.")
        expect(response).to redirect_to list_tree_display_index_path
      end
    end

    context 'when assignment is not deleted successfully' do
      it 'shows an error flash message and redirects to tree_display#list page' do
        asg = double('Assignmnet', instructor_id: 0)
        asg_form = double('AssignmentForm', id: 0, assignment: asg)
        allow(AssignmentForm).to receive(:create_form_object).and_return(asg_form)
        session[:user] = double('User', get_instructor: 1)
        params = {id: 0}
        get :delete, params
        expect(flash[:error]).to eq("You are not authorized to delete this assignment.")
        expect(response).to redirect_to list_tree_display_index_path
      end
    end
  end
end
