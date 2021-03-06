package why.pubsub.amqp;

import amqp.AmqpConnectionManager;

using tink.CoreApi;

@:genericBuild(why.pubsub.amqp.Amqp.build())
class Amqp<PubSub> {}

class AmqpBase {
	final manager:AmqpConnectionManager;
	
	public function new(manager) {
		this.manager = manager;
	}
	
	public function sync(config:AmqpConfig):Promise<Noise> {
		// TODO: remove existing bindings that are not specified in config
		return Future.async(function(cb) {
			var wrapped;
			wrapped = manager.createChannel({
				setup: channel -> {
					Promise.inParallel([for(exchange in config.exchanges) Promise.ofJsPromise(channel.assertExchange(exchange.name, exchange.type))])
						.next(_ -> Promise.inParallel([for(queue in config.queues) Promise.ofJsPromise(channel.assertQueue(queue.name, queue.options))]))
						.next(_ -> Promise.inParallel([for(queue in config.queues) for(binding in queue.bindings) Promise.ofJsPromise(channel.bindQueue(queue.name, binding.exchange, binding.pattern))]))
						.noise()
						.map(o -> {
							haxe.Timer.delay(function() wrapped.close(), 0);
							cb(o);
							o;
						})
						.asPromise()
						.swap((null:Any))
						.toJsPromise();
				}
			});
		});
	}
}

typedef AmqpConfig = {
	final exchanges:Array<ExchangeConfig>;
	final queues:Array<QueueConfig>;
}

typedef ExchangeConfig = {
	final name:String;
	final type:String;
}
typedef QueueConfig = {
	final name:String;
	final ?options:amqp.AmqpChannel.AmpqAssertQueueOptions;
	final bindings:Array<BindingConfig>;
}
typedef BindingConfig = {
	final exchange:String;
	final pattern:String;
}