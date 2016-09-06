#pragma once

#include <mbgl/actor/mailbox.hpp>
#include <mbgl/actor/message.hpp>
#include <mbgl/actor/actor_ref.hpp>
#include <mbgl/util/noncopyable.hpp>

#include <memory>

namespace mbgl {

template <class Object>
class Actor : public util::noncopyable {
public:
    template <class... Args>
    Actor(Scheduler& scheduler, Args&&... args_)
        : object(std::forward<Args>(args_)...),
          mailbox(std::make_shared<Mailbox>(scheduler)) {
    }

    ~Actor() {
        mailbox->close();
    }

    template <typename Fn, class... Args>
    void invoke(Fn fn, Args&&... args) {
        mailbox->push(actor::makeMessage(object, fn, std::forward<Args>(args)...));
    }

    operator ActorRef<std::decay_t<Object>> () {
        return ActorRef<std::decay_t<Object>>(object, mailbox);
    }

private:
    Object object;
    std::shared_ptr<Mailbox> mailbox;
};

} // namespace mbgl
