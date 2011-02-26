node.default[:travis][:user] = "travis"
node.default[:travis][:group] = "travis"
node.default[:travis][:deploy_to] = "/home/travis/travis"
node.default[:travis][:repository] = "https://github.com/svenfuchs/travis.git"
node.default[:travis][:ruby_version] = "1.8.7-p334"
node.default[:travis][:run_rails_app] = true
node.default[:traivs][:workers] = 4
node.default[:travis][:databases] = {
  :development => {
    :adapter => "postgresql",
    :database => "travis_development",
    :username => "travis",
    :pool => 5,
    :password => "secret"
  },
  :production => {
    :adapter => "postgresql",
    :database => "travis_production",
    :username => "travis",
    :pool => 5,
    :password => "secret"
  },
  :test => {
    :adapter => "postgresql",
    :database => "travis_production",
    :username => "travis",
    :pool => 5,
    :password => "secret"
  }
}
