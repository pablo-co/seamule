require 'sinatra/base'
require 'seamule'

if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
end

module SeaMule
  class Server < Sinatra::Base
    set :static, true

    def render_json(object)
      response['Cache-Control'] = 'max-age=0, private, must-revalidate'
      content_type :json
      begin
        object.to_json
      rescue Errno::ECONNREFUSED
        status 500
      end
    end

    get '/jobs.json' do
      render_json([])
    end

    post '/jobs.json' do
      job = SeaMule.pop_and_push(:pending, :active)
      if job
        render_json(job)
      else
        unprocessable_entity
      end
    end

    patch '/jobs/:id.json' do
      job = SeaMule.queued(:active, id: params[:id]).first
      if job
        job.result = read_json
        SeaMule.dequeue(:active, id: params[:id])
        SeaMule.push(:done, job)
        render_json(params.to_json)
        job.perform
      else
        unprocessable_entity
      end
    end

    def not_authorized
      status 403
    end

    def unprocessable_entity
      status 422
    end

    def read_json
      JSON.parse(request.env['rack.input'].read)
    end
  end
end
