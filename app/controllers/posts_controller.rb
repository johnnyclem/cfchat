# encoding : utf-8
class PostsController < BeautifulController

  before_filter :load_post, :only => [:show, :edit, :update, :destroy]

  # Uncomment for check abilities with CanCan
  #authorize_resource

  def index
    session[:fields] ||= {}
    session[:fields][:post] ||= (Post.columns.map(&:name) - ["id"])[0..4]
    do_select_fields(:post)
    do_sort_and_paginate(:post)
    
    @q = Post.search(
      params[:q]
    )

    @post_scope = @q.result(
      :distinct => true
    ).sorting(
      params[:sorting]
    )
    
    @post_scope_for_scope = @post_scope.dup
    
    unless params[:scope].blank?
      @post_scope = @post_scope.send(params[:scope])
    end
    
    @posts = @post_scope.paginate(
      :page => params[:page],
      :per_page => 20
    ).all

    respond_to do |format|
      format.html{
        if request.headers['X-PJAX']
          render :layout => false
        else
          render
        end
      }
      format.json{
        render :json => @post_scope.all 
      }
      format.csv{
        require 'csv'
        csvstr = CSV.generate do |csv|
          csv << Post.attribute_names
          @post_scope.all.each{ |o|
            csv << Post.attribute_names.map{ |a| o[a] }
          }
        end 
        render :text => csvstr
      }
      format.xml{ 
        render :xml => @post_scope.all 
      }             
      format.pdf{
        pdfcontent = PdfReport.new.to_pdf(Post,@post_scope)
        send_data pdfcontent
      }
    end
  end

  def show
    respond_to do |format|
      format.html{
        if request.headers['X-PJAX']
          render :layout => false
        else
          render
        end
      }
      format.json { render :json => @post }
    end
  end

  def new
    @post = Post.new

    respond_to do |format|
      format.html{
        if request.headers['X-PJAX']
          render :layout => false
        else
          render
        end
      }
      format.json { render :json => @post }
    end
  end

  def edit
    
  end

  def create
    @post = Post.create(params[:post])

    respond_to do |format|
      if @post.save
        format.html {
          if params[:mass_inserting] then
            redirect_to posts_path(:mass_inserting => true)
          else
            redirect_to post_path(@post), :notice => t(:create_success, :model => "post")
          end
        }
        format.json { render :json => @post, :status => :created, :location => @post }
      else
        format.html {
          if params[:mass_inserting] then
            redirect_to posts_path(:mass_inserting => true), :error => t(:error, "Error")
          else
            render :action => "new"
          end
        }
        format.json { render :json => @post.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    respond_to do |format|
      if @post.update_attributes(params[:post])
        format.html { redirect_to post_path(@post), :notice => t(:update_success, :model => "post") }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @post.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @post.destroy

    respond_to do |format|
      format.html { redirect_to posts_url }
      format.json { head :ok }
    end
  end

  def batch
    attr_or_method, value = params[:actionprocess].split(".")

    @posts = []    
    
    Post.transaction do
      if params[:checkallelt] == "all" then
        # Selected with filter and search
        do_sort_and_paginate(:post)

        @posts = Post.search(
          params[:q]
        ).result(
          :distinct => true
        )
      else
        # Selected elements
        @posts = Post.find(params[:ids].to_a)
      end

      @posts.each{ |post|
        if not Post.columns_hash[attr_or_method].nil? and
               Post.columns_hash[attr_or_method].type == :boolean then
         post.update_attribute(attr_or_method, boolean(value))
         post.save
        else
          case attr_or_method
          # Set here your own batch processing
          # post.save
          when "destroy" then
            post.destroy
          end
        end
      }
    end
    
    redirect_to :back
  end

  def treeview

  end

  def treeview_update
    modelclass = Post
    foreignkey = :post_id

    render :nothing => true, :status => (update_treeview(modelclass, foreignkey) ? 200 : 500)
  end
  
  private 
  
  def load_post
    @post = Post.find(params[:id])
  end
end

