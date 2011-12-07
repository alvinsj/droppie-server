require 'sinatra'

require 'json'
require 'fileutils'

# "authentication" filter
before /\/api\/v1\/*/ do
  content_type :json
  raise Sinatra::NotFound if params[:u].nil? or params[:k].nil?
  
  raise Sinatra::NotFound unless params[:u]=="alvin" || params[:k]=="beer"
end

# login
get '/api/v1/login' do
  {:folders=>print_folders("store") }.to_json
end


# get folder info
get '/api/v1/folder' do
  raise Sinatra::NotFound unless validate_id( params[:folder_id] )
  
  if File.ftype(params[:folder_id]) == "file" 
    {:error=>"it is a file" }.to_json
  else
    {:folders=>print_folders( params[:folder_id] ) }.to_json
  end
  
end

# update folder/file
put '/api/v1/manage' do
  raise Sinatra::NotFound unless validate_id( params[:folder_id] ) 
  raise Sinatra::NotFound if params[:name].nil? || params[:name].empty?
  
  path = File.dirname(params[:folder_id])

  respond_with do
    File.rename(params[:folder_id], "#{path}/#{params[:name]}")
  end

end

# delete folder/file 
delete '/api/v1/manage' do
  raise Sinatra::NotFound unless validate_id( params[:folder_id] )
  
  respond_with do
    File.delete(params[:folder_id])
  end
end

# create folder 
post '/api/v1/manage' do
  raise Sinatra::NotFound unless validate_id( params[:folder_id], false )
  
  respond_with do
    FileUtils.mkdir(params[:folder_id])
  end
end

# uploade file
post '/api/v1/upload' do
  raise Sinatra::NotFound unless validate_id( params[:folder_id] )
  raise Sinatra::NotFound if params[:file].nil?
  
  respond_with do
    tempfile = params[:file][:tempfile]
    name = File.basename(tempfile)

    FileUtils.cp(tempfile.path, "#{params[:folder_id]}/#{name}")
  end

end

# download file
get '/api/v1/download' do
  raise Sinatra::NotFound unless validate_id( params[:folder_id] )
  
  send_file(params[:folder_id])
end

# wrap to response
def respond_with
  begin
    yield
  rescue
    return {:error=>"Operation failed"}.to_json
  end 
  {:result => "OK"}.to_json
end

# list folders
def print_folders( root )
  raise Sinatra::NotFound if root.nil?
  Dir.glob("#{root}/*").map do|filename|
    { :folder_id => filename, 
      :name => File.basename(filename)
      :type => (File.directory?(filename) ? "d" : "f" )}
  end 
end

# validate folder_id
def validate_id( folder_id, test=true )
 
  if folder_id.nil? || 
    folder_id.empty? || 
    folder_id =~ /^\/.*/ || #/
    folder_id =~ /\.\./  #..
    !(folder_id =~ /^store.*/ )
    false
  else
    
    begin
      f = File.open(folder_id,"r")
    rescue
      return false
    end if test
    
    true
  end
end
