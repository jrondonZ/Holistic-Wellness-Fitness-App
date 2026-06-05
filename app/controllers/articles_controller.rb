class ArticlesController < ChartController
  def index
    @category   = params[:category].presence
    @articles   = Article.by_category(@category).newest
    @categories = Article::CATEGORIES
    @featured   = Article.newest.first unless @category
  end

  def show
    @article = Article.find(params[:id])
    @more    = Article.where(category: @article.category).where.not(id: @article.id).newest.limit(3)
  end
end
