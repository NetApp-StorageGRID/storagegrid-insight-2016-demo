require 'sinatra'
require 'haml'
require 'aws-sdk'

endpoint = 'https://' + ENV['STORAGEGRID_ENDPOINT']
bucket = ENV['STORAGEGRID_BUCKET']

credentials = Aws::SharedCredentials.new(profile_name: ENV['S3_PROFILE'])
client = Aws::S3::Client.new(region: 'us-east-1', endpoint: endpoint, credentials: credentials,
                             force_path_style: true, ssl_verify_peer: false)
s3 = Aws::S3::Resource.new(client: client)

get "/" do
  haml :index
end

post "/upload" do 
  @key = SecureRandom.hex(32);
  s3.bucket(bucket).object(@key).put(
    body: params['file'][:tempfile].read,
    server_side_encryption: 'AES256',
    metadata: {'sender' => params['sender'], 'message' => Base64.strict_encode64(params['message']),
               'filename' => params['file'][:filename]}
  )
  haml :success
end

get "/:id" do
  @key = params[:id]
  object = s3.bucket(bucket).object(@key)
  metadata = object.metadata
  @sender, @filename, @message = metadata['sender'], metadata['filename'], Base64.strict_decode64(metadata['message'])
  @size = (object.content_length.to_i / 1024.0 / 1024.0).round(1)
  haml :download
end

get "/:id/download" do
  object = s3.bucket(bucket).object(params[:id])
  filename = object.metadata['filename']
  url = object.presigned_url(:get, expires_in: 900, response_content_disposition: 'attachment;filename=' + filename)
  redirect url
end
