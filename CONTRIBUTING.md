We love pull requests. Here's a quick guide:

1. Fork the repo, and make your changes.

2. Once you're ready to submit, rebase your branch against our master branch to
maintain a clean history and ensure you're up to date with all the most recent
changes.

3. Run the tests. We only take pull requests with passing tests, and it's great
to know that you have a clean slate: `bundle && rake`

4. Add a test for your change. Only refactoring and documentation changes
require no new tests. If you are adding functionality or fixing a bug, we need
a test!

5. Make the test pass.

6. Push to your fork and submit a pull request.


At this point you're waiting on us. We like to at least comment on, if not
accept, pull requests within three business days (and, typically, one business
day). We may suggest some changes or improvements or alternatives. Your pull request
will be built by [Travis](https://travis-ci.org/ingenerator/vagrant-mirror) first - 
if the build fails please fix that first.

Some things that will increase the chance that your pull request is accepted,
taken straight from the Ruby on Rails guide:

* Include tests that fail without your code, and pass with it
* Update the documentation, the surrounding one, examples elsewhere, guides,
  whatever is affected by your contribution

Syntax:

* Two spaces, no tabs.
* No trailing whitespace. Blank lines should not have any space.
* Prefer &&/|| over and/or.
* MyClass.my_method(my_arg) not my_method( my_arg ) or my_method my_arg.
* a = b and not a=b.
* Follow the conventions you see used in the source already.

And in case we didn't emphasize it enough: we love tests!