# Seller Selection System Optimizations

## 1. Database Index Recommendations

### Critical Missing Indexes
```sql
-- VariantAdoption table
CREATE INDEX idx_variant_adoptions_variant_id ON spree_variant_adoptions(variant_id);
CREATE INDEX idx_variant_adoptions_user_id ON spree_variant_adoptions(user_id);
CREATE INDEX idx_variant_adoptions_price ON spree_variant_adoptions((default_price->>'amount'));

-- Users table  
CREATE INDEX idx_users_seller_rank ON spree_users(seller_rank) WHERE seller_rank IS NOT NULL;
CREATE INDEX idx_users_active ON spree_users(id) WHERE deleted_at IS NULL AND active = true;
```

## 2. Caching Strategies

### Implementation Options
```ruby
# Redis-based caching
def load_sellers_of_variant(variant)
  Rails.cache.fetch("variant/#{variant.id}/sellers", expires_in: 1.hour) do
    variant.variant_adoptions
      .joins(:user)
      .where(users: { deleted_at: nil, active: true })
      .order(Arel.sql("users.seller_rank DESC, (50000 - (variant_adoptions.default_price->>'amount')::numeric) DESC"))
      .limit(1)
      .to_a
  end
end

# Fragment caching in views
<% cache [@product, @sellers] do %>
  <!-- seller display logic -->  
<% end %>
```

## 3. Query Optimizations

### Current vs Optimized Approach

**Current:**
```ruby
# In-memory sorting of all records
@sellers = variant.variant_adoptions.includes(:default_price)
  .all
  .sort{|x,y| y.seller_based_sort_rank <=> x.seller_based_sort_rank }[0,1]
```

**Optimized:**
```ruby
# SQL-based sorting with limits
@sellers = variant.variant_adoptions
  .joins(:user, :default_price)
  .where(users: { deleted_at: nil, active: true })
  .order("users.seller_rank DESC, (50000 - spree_prices.amount) DESC")
  .limit(1)
```

## 4. Architectural Improvements

### Precomputed Rankings
```ruby
# Add to VariantAdoption model
class VariantAdoption < ApplicationRecord
  after_save :update_ranking_score

  def update_ranking_score
    update_column(
      :ranking_score, 
      user.seller_rank + (50000 - price_in(Spree::Config[:currency]).amount)
    )
  end
end

# Then query becomes:
@sellers = variant.variant_adoptions
  .where("ranking_score > 0")
  .order(ranking_score: :desc)
  .limit(1)
```

## 5. Performance Monitoring

### Key Metrics to Track
1. **Query Times**: For seller loading
2. **Memory Usage**: During sorting operations  
3. **Cache Hit Rates**: For seller selections
4. **90th Percentile Response Times**: For product pages

### Suggested Alerts
- Seller selection queries > 100ms
- Product page renders > 500ms
- Redis cache misses > 20%
