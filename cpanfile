requires 'Object::Pad', '>= 0.800';
requires 'IO::Async', 0;
requires 'Net::Async::HTTP', '>= 0.49';
requires 'IO::Async::SSL', '>= 0.25';
requires 'Syntax::Keyword::Try', '>= 0.29';
requires 'Future', '>= 0.50';
requires 'Future::AsyncAwait', '>= 0.66';
requires 'URI', 0;
requires 'Log::Any', '>= 1.717';
#requires 'Log::Any::Adapter', '>= 1.709';

requires 'Cache::LRU', '>= 0.04';

on 'build' => sub {
    requires 'Dist::Zilla', '>= 6.015';
    requires 'Dist::Zilla::PluginBundle::Author::VNEALV';
    requires 'Software::License::Perl_5';
};

on 'test' => sub {
    requires 'Test::More', '>= 0.98';
    requires 'Test::NoTabs';
};
