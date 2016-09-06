#pragma once

#include <memory>

namespace mbgl {

class Mailbox;

class Scheduler {
public:
    virtual ~Scheduler() = default;
    virtual void schedule(std::weak_ptr<Mailbox>) = 0;
};

} // namespace mbgl
