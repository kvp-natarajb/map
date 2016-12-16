class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.all
    @places = Place.all
    @hash = Gmaps4rails.build_markers(@users) do |user, marker|
      marker.lat user.latitude
      marker.lng user.longitude
      marker.infowindow user.address
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
  
  end

  def display_list
    @allotment = Allotment.new
    session["user_id"] = params[:id]
    if session["user_id"].present?
      @user = User.find(session["user_id"])
      @allotments = @user.allotment.order('position')
      @places_list = @user.places
      if @user.geocoded? && params[:range].present?
        @places = @places_list.near(@user.address, params[:range].to_i, :order => false, :units => :km)  
        if @places.empty?
          @allotments = []
        else
          @allotments.each do |allotment|
            record = @places.where(id: allotment.place_id)
            if record.empty?
              @allotments = @allotments - [allotment]
            end
          end
        end
        @places = @places + [@user] 
      else 
        @places = @places_list + [@user]
      end
      @hash = Gmaps4rails.build_markers(@places) do |place, marker|
        @place = place
        marker.lat place.latitude
        marker.lng place.longitude
        if place.class.name=="Place"
          marker.picture ({:url => ActionController::Base.helpers.asset_path('marker-blue.png'),
                      :width => 32,
                      :height => 32})
          marker.infowindow render_to_string(:action => 'new_allotment', :layout => false)    
          marker.json({ :id => @place.id })
        end
      end
      session["allotment_list"] = @allotments
    end
    respond_to do |format|
      format.js 
    end
  end

  def create_allotment
    @user = User.find(params[:allotment][:user_id])
    @allotments = @user.allotment.order('position')
    @places_list = @user.places
    if @user.geocoded? && params[:range].present?
      @places = @places_list.near(@user.address, params[:range].to_i, :order => false, :units => :km)  
      if @places.empty?
        @allotments = []
      else
        @allotments.each do |allotment|
          record = @places.where(id: allotment.place_id)
          if record.empty?
            @allotments = @allotments - [allotment]
          end
        end
      end
      @places = @places + [@user] 
    else 
      @places = @places_list + [@user]
    end
    @allotment = Allotment.new(allotment_params)
    record = @allotments.find_by_user_id_and_place_id(@allotment.user_id,@allotment.place_id)
    respond_to do |format|
      if !record && @allotment.save
        @allotments = @allotments + [@allotment]
      end
      format.js
    end
  end


  def sort
    @allotment = Allotment.new
    params[:allotment].each_with_index do |id, index|
      Allotment.find(id).update(position: index+1)
    end
    @user = Allotment.find(params[:allotment][0]).user
    @allotments = @user.allotment.order('position')
    @places_list = @user.places
    if @user.geocoded? && params[:range].present?
      @places = @places_list.near(@user.address, params[:range].to_i, :order => false, :units => :km)  
      if @places.empty?
        @allotments = []
      else
        @allotments.each do |allotment|
          record = @places.where(id: allotment.place_id)
          if record.empty?
            @allotments = @allotments - [allotment]
          end
        end
      end
      @places = @places + [@user] 
    else 
      @places = @places_list + [@user]
    end
    session["allotment_list"] = @allotments
    @hash = Gmaps4rails.build_markers(@places) do |place, marker|
      @place = place
      marker.lat place.latitude
      marker.lng place.longitude
      if place.class.name=="Place"
        marker.picture ({:url => ActionController::Base.helpers.asset_path('marker-blue.png'),
                    :width => 32,
                    :height => 32})
        marker.infowindow render_to_string(:action => 'new_allotment', :layout => false)    
        marker.json({ :id => @place.id })
      end
    end
    respond_to do |format|
      format.js { render "create_allotment.js.erb" }
    end
  end

  def direction_info
    user = User.find(session["user_id"])
    allotment_list = session["allotment_list"]
    if allotment_list.present? && user.present?
      destination =  Place.find(allotment_list.last["place_id"])
      allotment_list = allotment_list - [allotment_list.last]
      waypts=[]
      allotment_list.each_with_index do |allotment,index|
        waypts[index]={
          location:  Place.find(allotment['place_id']).address,
          stopover: true
        }
      end
      @request = {
        origin: user.address,
        destination: destination.address,
        travelMode: params[:travelMode].present? ? params[:travelMode] : "DRIVING",
        waypoints: waypts,
        optimizeWaypoints: true
      }
    else
      @request = {}
    end
    respond_to do |format|
      format.json  { render :json => @request.to_json }
    end
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:latitude, :longitude, :name, :address, :title)
    end

    def allotment_params
      params.require(:allotment).permit(:date, :position, :user_id, :place_id)
    end
end
