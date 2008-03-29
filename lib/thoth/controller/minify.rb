#--
# Copyright (c) 2008 Ryan Grove <ryan@wonko.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#   * Neither the name of this project nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#++

class MinifyController < Ramaze::Controller
  engine :Erubis
  helper :cache, :error
  layout '/layout'
  
  template_root Thoth::Config.theme.view/:admin,
                Thoth::VIEW_DIR/:admin

  def css(*args)
    path = 'css/' << args.join('/')
    
    if Thoth::Config.server.enable_cache
      response.body = value_cache[path] ||
          value_cache[path] = CSSMin.minify(process(path))
    else
      response.body = CSSMin.minify(process(path))
    end
    
    response['Content-Type'] = 'text/css'

    throw(:respond)
  end
  
  def js(*args)
    path = 'js/' << args.join('/')
    
    if Thoth::Config.server.enable_cache
      response.body = value_cache[path] ||
          value_cache[path] = JSMin.minify(process(path))
    else
      response.body = JSMin.minify(process(path))
    end

    response['Content-Type'] = 'text/javascript'

    throw(:respond)
  end
  
  private
  
  def process(path)
    error_404 unless file = Ramaze::Dispatcher::File.open_file(path)
    
    if file == :NotModified
      response.build([], 304)
      throw(:respond)
    end
    
    file
  end
end