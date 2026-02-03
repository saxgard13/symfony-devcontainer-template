# Redis Cache

Redis is included by default for caching and session storage.

## Configuration in Symfony

### 1. Install the Redis adapter

```bash
composer require symfony/cache
```

### 2. Add to your `.env`

```env
REDIS_URL=redis://redis:6379
```

### 3. Configure cache

In `config/packages/cache.yaml`:

```yaml
framework:
    cache:
        app: cache.adapter.redis
        default_redis_provider: '%env(REDIS_URL)%'
```

### 4. (Optional) Use Redis for sessions

In `config/packages/framework.yaml`:

```yaml
framework:
    session:
        handler_id: '%env(REDIS_URL)%'
```

## Usage Example

```php
use Symfony\Contracts\Cache\CacheInterface;

class ProductController extends AbstractController
{
    #[Route('/products', name: 'product_list')]
    public function list(CacheInterface $cache, ProductRepository $repository): Response
    {
        // First call: executes the query and stores result in Redis
        // Next calls: returns cached data (much faster)
        $products = $cache->get('products_list', function() use ($repository) {
            return $repository->findAllWithCategories();
        });

        return $this->json($products);
    }
}
```

## Cache Invalidation

The cache doesn't know when your data changes. You need to handle invalidation.

### Strategy 1: TTL (Time To Live)

Cache expires automatically after a set time:

```php
use Symfony\Contracts\Cache\ItemInterface;

$products = $cache->get('products_list', function(ItemInterface $item) use ($repository) {
    $item->expiresAfter(3600); // Expires after 1 hour
    return $repository->findAll();
});
```

### Strategy 2: Manual Invalidation

Delete cache when data changes:

```php
public function create(Product $product, CacheInterface $cache): Response
{
    $this->entityManager->persist($product);
    $this->entityManager->flush();

    $cache->delete('products_list'); // Invalidate cache

    return $this->json($product);
}
```

### Strategy 3: Doctrine Event Listener

Automatic invalidation when entities change:

```php
// src/EventListener/CacheInvalidator.php
use Doctrine\ORM\Events;
use Doctrine\Bundle\DoctrineBundle\Attribute\AsDoctrineListener;

class CacheInvalidator
{
    public function __construct(private CacheInterface $cache) {}

    #[AsDoctrineListener(event: Events::postPersist, entity: Product::class)]
    #[AsDoctrineListener(event: Events::postUpdate, entity: Product::class)]
    #[AsDoctrineListener(event: Events::postRemove, entity: Product::class)]
    public function invalidate(): void
    {
        $this->cache->delete('products_list');
    }
}
```

## Which Strategy to Use?

| Strategy | Use case |
|----------|----------|
| **TTL** | Data that can be slightly stale (stats, public lists) |
| **Manual** | Critical data, few modification points |
| **Event Listener** | Many modification points, need automation |

## Disabling Redis

If you don't need Redis, remove it from `devcontainer.json`:

```json
"dockerComposeFile": [
  "docker-compose.dev.yml",
  "docker-compose.mysql.yml"
  // Remove: "docker-compose.redis.yml"
],
```

Then rebuild the container.
