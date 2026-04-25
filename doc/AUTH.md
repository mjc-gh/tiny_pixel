# Authentication & Authorization

tiny_pixel uses **ReviseAuth** for session-based authentication with password hashing, password reset, and email confirmation.

Controllers requiring authentication use:

```ruby
before_action :authenticate_user!
```

## Multi-Tenant Authorization

tiny_pixel is multi-tenant at the site level. Site-specific controllers follow this pattern:

```ruby
class Sites::MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site # set @site from params[:site_id]
  before_action :authorize_site_admin!, only: [:edit, :update] # limit to admin role
end
```

### Conditional Email Delivery

The `UserReviseExtension` module conditionally sends emails based on `TinyPixel.email_delivery_supported?`:

```ruby
module UserReviseExtension
  def send_confirmation_instructions
    super if TinyPixel.email_delivery_supported?
  end

  def send_password_reset_instructions
    super if TinyPixel.email_delivery_supported?
  end
end
```

**Controller usage:**

```ruby
flash[:notice] = if TinyPixel.email_delivery_supported?
  t("memberships.create.success_invited")
else
  t("memberships.create.success")
end
```

## Email-Optional Features

1. **Check capability:** `return unless user || TinyPixel.email_delivery_supported?`
2. **Branch logic:** Conditionally call email methods
3. **Test both:** Stub `email_delivery_supported?` as `true` and `false`

## Testing Authorization

### Testing Authentication Requirements

```ruby
test "index redirects unauthenticated users" do
  get site_memberships_url(sites(:my_blog))
  assert_redirected_to login_path
end
```

### Testing Authorization

```ruby
test "index returns 403 for non-admin members" do
  login(users(:bob))  # Bob is a member, not admin
  get site_memberships_url(sites(:my_blog))
  assert_response :forbidden
end

test "index allows admins" do
  login(users(:alice))  # Alice is an admin
  get site_memberships_url(sites(:my_blog))
  assert_response :success
end
```

## Related Files

- `app/models/user.rb` - User model with authorization helpers
- `app/models/user_revise_extension.rb` - Email delivery conditional wrapper
- `app/controllers/application_controller.rb` - Base controller with common helpers
- `app/controllers/sites/` - Site-scoped controllers using the authorization pattern
