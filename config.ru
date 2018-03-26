require_relative 'config/environment'

use Middleware::AppLogger
run Simpler.application
