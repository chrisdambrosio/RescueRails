class AdoptersController < ApplicationController
  include SessionsHelper

  before_filter :authenticate, :except => [:new, :create, :check_email]
  before_filter :edit_my_adopters_user, :only => [:index, :show, :edit, :update]
  before_filter :edit_all_adopters_user, :only => [:index, :show, :edit, :update]
  before_filter :admin_user, :only => [:destroy]

  respond_to :html, :json

  def index
    @title = "Adoption Applications"

    statuses = ['new', 'pend response', 'workup', 'approved']

    if params[:search]
      @adopters = Adopter.where('lower(name) LIKE ?', "%#{params[:search].downcase.strip}%")
    elsif params[:status] == 'active'
      @adopters = Adopter.where("status IN (?)", statuses).includes(:user, :comments, :dogs, :adoption_app)
      # @adopters = Adopter.find(:all, :include => [:user, :comments, :dogs, :adoption_app], :conditions => ["status IN ?", statuses])
    elsif params.has_key? :status
      @adopters = Adopter.where(:status => params[:status]).includes(:user, :comments, :dogs, :adoption_app)
    else
      @adopters = Adopter.find(:all, :include => [:user, :comments, :dogs, :adoption_app])
    end

    session[:last_search] = request.url
  end

  def show
    session[:last_search] ||= adopters_url
    @adopter = Adopter.find(params[:id])
    @adoption_app = @adopter.adoption_app
    @title = @adopter.name
    @dogs_all = Dog.order("name").all
    @adoption = Adoption.new
    @adopter_users = User.where(:edit_my_adopters => true).order("name")
  end

  def new
    @title = "Adoption Application"
    @adopter = Adopter.new
    @adopter.adoption_app = AdoptionApp.new
    @adopter.dog_name = params[:dog_name]
    3.times do
      @adopter.references.build
    end
  end

  def create
    @adopter = Adopter.new(params[:adopter])
    @adopter.status = 'new'

    if !@adopter.adoption_app.ready_to_adopt_dt
      @adopter.adoption_app.ready_to_adopt_dt = Date.today
    end

    if @adopter.save
      @adopter.adoptions.each do |a|
        a.relation_type = 'interested'
        a.save
      end
      NewAdopterMailer.adopter_created(@adopter.id).deliver
      AdoptAppMailer.adopt_app(@adopter.id).deliver
      flash[:success] = "adoptsuccess"
      redirect_to root_path(:adoptapp => "complete")
    else
      render 'new'
    end
  end

  def update
    @adopter = Adopter.find(params[:id])

    if (params[:adopter][:status] == 'completed') && (!can_complete_adopters?)
      flash[:error] = "You are not allowed to set an application to completed"
    else
      @adopter.updated_by_admin_user = current_user
      @adopter.update_attributes(params[:adopter])
      flash[:success] = "Application Updated"
    end

    respond_with(@adopter) do |format|
      format.html { render }
      format.json { render json: @adopter }
    end
  end

  def check_email
    @adopter = Adopter.find_by_email(params[:adopter][:email])

    respond_to do |format|
      format.json { render :json => !@adopter }
    end
  end

  private

  def edit_my_adopters_user
    #TODO Figure out how to differentiate these
    redirect_to(root_path) unless current_user.edit_my_adopters? || current_user.edit_all_adopters?
  end

  def edit_all_adopters_user
    #TODO Figure out how to differentiate these
    redirect_to(root_path) unless current_user.edit_all_adopters?
  end
end
