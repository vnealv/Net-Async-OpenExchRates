package Net::Async::OpenExchRates;

# ABSTRACT: Interaction with OpenExchangeRates API

use Object::Pad;

class Net::Async::OpenExchRates :isa(IO::Async::Notifier);

# VERSION

# AUTHORITY

=head1 NAME

Net::Async::OpenExchRates - interact with OpenExchangeRates API via L<IO::Async>

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

field $_api_key :accessor;

method configure_unknown(%args) {

}

method _add_to_loop {
}

method test() {
    print "hI";
    print $self->api_key;
}
1;
