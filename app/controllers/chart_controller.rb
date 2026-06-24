# Base controller for every authenticated "inside the chart" screen.
# Renders inside the chart layout (top bar + left chart navigation rail).
class ChartController < ApplicationController
  layout "chart"
  before_action :require_legal_acceptance
end
