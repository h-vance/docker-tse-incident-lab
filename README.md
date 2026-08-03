# Docker TSE Incident Lab

A terminal-first portfolio lab for practicing evidence-driven Docker troubleshooting in realistic Technical Support Engineering incidents.

## What this demonstrates

- Container status and log investigation
- Runtime environment comparison
- Container-to-container service addressing
- Database authentication troubleshooting
- Failure reproduction, scoped correction, and customer-workflow verification
- Safe reset between exercises

## Requirements

- Docker Desktop with Docker Compose
- `make`
- `curl`

## Five-minute start

```bash
# Clone and enter the repository.
git clone https://github.com/h-vance/docker-tse-incident-lab.git
cd docker-tse-incident-lab

# Start the first deliberately broken incident.
make incident-1

# Reprint the customer ticket at any time.
make ticket
```

Investigate using normal Docker evidence:

```bash
# Show running, stopped, restarting, and unhealthy containers.
docker ps -a

# Read the application service logs.
docker compose logs --tail 100 app

# Inspect the active generated override after collecting runtime evidence.
sed -n '1,120p' compose.override.yaml
```

Edit `compose.override.yaml`, then apply and verify:

```bash
# Recreate the services with your corrected override.
make apply

# Test the real customer-facing /customers workflow.
make verify
```

If stuck:

```bash
# Reveal the concise answer for the active incident.
make answer

# Restore the healthy baseline without deleting database data.
make reset
```

## Incidents

| Incident | Customer symptom | Skill |
|---|---|---|
| 1 | Application unavailable after deployment | Missing required environment variable |
| 2 | Application returns `503` after a Compose change | Wrong database hostname |
| 3 | Application returns `503` after credential rotation | Wrong database password |

## Investigation structure

For every incident, record:

1. Customer impact
2. First evidence source
3. Confirmed facts
4. Hypothesis
5. Root cause
6. Scoped resolution
7. Verification evidence

## Safety

- All credentials and customer data are synthetic.
- The application binds only to `127.0.0.1:8099` on the host.
- Reset does not remove the named PostgreSQL volume.
- No scenario fills host storage or consumes unbounded memory.
- Container CPU, memory, and process counts are bounded; the named volume remains subject to the Docker Desktop disk limit.

## Maintainer verification

```bash
# Confirm every incident fails as designed and the baseline recovers.
make test
```

## License

MIT
