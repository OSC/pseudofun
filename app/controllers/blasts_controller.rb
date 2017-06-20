class BlastsController < ApplicationController
  before_action :set_blast, only: [:show, :edit, :update, :destroy, :submit, :copy]

  # GET /blasts
  # GET /blasts.json
  def index
    @blasts = Blast.preload(:blast_jobs)
  end

  # GET /blasts/1
  # GET /blasts/1.json
  def show
  end

  # GET /blasts/new
  def new
    @blast = Blast.new
  end

  # GET /blasts/1/edit
  def edit
  end

  # POST /blasts
  # POST /blasts.json
  def create
    @blast = Blast.new(blast_params)

    respond_to do |format|
      if @blast.save
        format.html { redirect_to @blast, notice: 'Blast was successfully created.' }
        format.json { render :show, status: :created, location: @blast }
      else
        format.html { render :new }
        format.json { render json: @blast.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /blasts/1
  # PATCH/PUT /blasts/1.json
  def update
    respond_to do |format|
      if @blast.update(blast_params)
        format.html { redirect_to @blast, notice: 'Blast was successfully updated.' }
        format.json { render :show, status: :ok, location: @blast }
      else
        format.html { render :edit }
        format.json { render json: @blast.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /blasts/1
  # DELETE /blasts/1.json
  def destroy
    respond_to do |format|
      if @blast.destroy
        format.html { redirect_to blasts_url, notice: 'Blast was successfully destroyed.' }
        format.json { head :no_content }
      else
        format.html { redirect_to blasts_url, alert: "Blast failed to be destroyed: #{@blast.errors.to_a}" }
        format.json { render json: @blast.errors, status: :internal_server_error }
      end
    end
  end

  # PUT /blasts/1/submit
  # PUT /blasts/1/submit.json
  def submit
    respond_to do |format|
      if @blast.submitted?
        format.html { redirect_to blasts_url, alert: 'Blast has already been submitted.' }
        format.json { head :no_content }
      elsif @blast.submit
        format.html { redirect_to blasts_url, notice: 'Blast was successfully submitted.' }
        format.json { head :no_content }
      else
        format.html { redirect_to blasts_url, alert: "Blast failed to be submitted: #{@blast.errors.to_a}" }
        format.json { render json: @blast.errors, status: :internal_server_error }
      end
    end
  end

  # PUT /blasts/1/copy
  def copy
    @blast = @blast.copy

    respond_to do |format|
      if @blast.save
        format.html { redirect_to @blast, notice: 'Blast was successfully copied.' }
        format.json { render :show, status: :created, location: @blast }
      else
        format.html { redirect_to blasts_url, alert: "Blast failed to be copied: #{@blast.errors.to_a}" }
        format.json { render json: @blast.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_blast
      @blast = Blast.preload(:blast_jobs).find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def blast_params
      params.require(:blast).permit!
    end
end